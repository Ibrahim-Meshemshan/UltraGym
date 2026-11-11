import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../data/repo/sell_membership_repository.dart';
import '../../domain/models/sale_models.dart';

part 'sell_membership_state.dart';

/// فتح شاشة البيع: عضو من الرابط (`?player_id=`) وفرع البيع المعروف (الشريط العلوي) لتصفية الخطط.
typedef SellArgs = ({int? playerId, int? branchId});

/// بيع اشتراك (`SellMembership.html`): يطلب التسعير من الخادم مع كل تغيير يؤثر فيه
/// (الخطة، تاريخ البداية، الكوبون، الخصم اليدوي) ويتجاهل رداً وصل لاختيار أقدم.
class SellMembershipCubit extends Cubit<SellState> {
  SellMembershipCubit(this._repo, this.args) : super(const SellState());

  final SellMembershipRepository _repo;
  final SellArgs args;
  int _quoteSeq = 0;
  IdempotencyKeeper _keeper = IdempotencyKeeper();

  /// مفتاح البيع: نفس الجسم عند إعادة المحاولة = نفس المفتاح (لا بيع مكرر).
  String keyFor(Json body) => _keeper.keyFor(body);

  /// الخطط والعضو المحدد بالرابط بالتوازي.
  Future<void> load() async {
    final playerId = args.playerId;
    emit(state.copyWith(plans: state.plans.toLoading(), member: playerId == null ? null : state.member.toLoading()));
    final plans = _repo.plans(branchId: args.branchId);
    final member = playerId == null ? null : _repo.member(playerId);
    final (p, m) = (await plans, await member);
    if (isClosed) return;
    emit(state.copyWith(plans: state.plans.fromResult(p), member: m == null ? null : state.member.fromResult(m)));
  }

  Future<void> retryPlans() async {
    emit(state.copyWith(plans: state.plans.toLoading()));
    final r = await _repo.plans(branchId: args.branchId);
    if (isClosed) return;
    emit(state.copyWith(plans: state.plans.fromResult(r)));
  }

  Future<void> retryMember() async {
    final id = args.playerId;
    if (id == null) return;
    emit(state.copyWith(member: state.member.toLoading()));
    final r = await _repo.member(id);
    if (isClosed) return;
    emit(state.copyWith(member: state.member.fromResult(r)));
  }

  void pickMember(SaleMember m) => emit(state.copyWith(member: const Slice<SaleMember>().toSuccess(m)));

  void clearMember() => emit(state.copyWith(member: const Slice()));

  Future<void> selectPlan(int id) async {
    if (id == state.planId) return;
    emit(state.copyWith(planId: () => id));
    if (state.needsTrainer && state.trainers.isInitial) unawaited(loadTrainers());
    await _requote();
  }

  Future<void> loadTrainers() async {
    emit(state.copyWith(trainers: state.trainers.toLoading()));
    final r = await _repo.trainers();
    if (isClosed) return;
    emit(state.copyWith(trainers: state.trainers.fromResult(r)));
  }

  Future<void> setStart(DateTime? day) async {
    if (day == state.startsOn) return;
    emit(state.copyWith(startsOn: () => day));
    await _requote();
  }

  /// تبديل نوع الخصم يلغي المطبّق من النوع الآخر.
  Future<void> setMode(DiscountMode mode) async {
    if (mode == state.mode) return;
    final hadDiscount = state.coupon != null || state.discount != null;
    emit(state.copyWith(mode: mode, coupon: () => null, discount: () => null, discountError: () => null));
    if (hadDiscount) await _requote();
  }

  /// يطبّق الكوبون إن قبله الخادم، وإلا يبقى السابق ويظهر السبب. نص فارغ = إزالة الكوبون.
  Future<void> applyCoupon(String raw) {
    final code = raw.trim().toUpperCase();
    return _tryDiscount(coupon: code.isEmpty ? null : code, discount: null);
  }

  /// الخصم اليدوي بالدولار (للمالك؛ الخادم يرفضه لغيره). null أو صفر = بلا خصم.
  Future<void> applyDiscount(double? usd) => _tryDiscount(coupon: null, discount: (usd ?? 0) > 0 ? usd : null);

  Future<void> retryQuote() => _requote();

  void done(SaleResult r) => emit(state.copyWith(result: () => r));

  /// بيع آخر: تبقى الخطط والمدربون ويُمسح الباقي.
  void startOver() {
    _keeper = IdempotencyKeeper();
    emit(SellState(plans: state.plans, trainers: state.trainers));
  }

  Future<void> _tryDiscount({required String? coupon, required double? discount}) async {
    if (state.planId == null) {
      emit(state.copyWith(coupon: () => coupon, discount: () => discount, discountError: () => null));
      return;
    }
    final before = state.quote;
    final r = await _quote(coupon: coupon, discount: discount);
    if (r == null) return;
    switch (r) {
      case ApiSuccess(:final data):
        emit(
          state.copyWith(
            coupon: () => coupon,
            discount: () => discount,
            discountError: () => null,
            quote: state.quote.toSuccess(data),
          ),
        );
      case ApiFailure(:final failure)
          when failure.type == FailureType.validation || failure.type == FailureType.forbidden:
        emit(state.copyWith(discountError: () => failure.message, quote: before));
      case ApiFailure(:final failure):
        emit(state.copyWith(quote: state.quote.toFailure(failure)));
    }
  }

  Future<void> _requote() async {
    if (state.planId == null) return;
    final r = await _quote(coupon: state.coupon, discount: state.discount);
    if (r == null) return;
    emit(state.copyWith(quote: state.quote.fromResult(r)));
  }

  /// يرجع null إن وصل رد أحدث منه (اختيار تغيّر أثناء الانتظار).
  Future<ApiResult<MembershipQuote>?> _quote({String? coupon, double? discount}) async {
    final seq = ++_quoteSeq;
    emit(state.copyWith(quote: state.quote.toLoading()));
    final r = await _repo.quote({
      'plan_id': state.planId,
      if (state.startsOn != null) 'starts_on': Formatters.date(state.startsOn),
      'coupon_code': ?coupon,
      'discount_usd': ?discount,
    });
    return isClosed || seq != _quoteSeq ? null : r;
  }
}
