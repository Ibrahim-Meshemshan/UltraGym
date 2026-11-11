import 'token_store_base.dart';

export 'token_store_base.dart';

/// خارج المتصفح (اختبارات VM فقط لهذه الواجهة): مخزن بالذاكرة.
TokenStore createTokenStore() => MemoryTokenStore();
