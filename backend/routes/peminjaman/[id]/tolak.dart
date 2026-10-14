import 'package:dart_frog/dart_frog.dart';

import '../../../lib/src/api.dart';

// Tambahkan ', String id' di sini
Future<Response> onRequest(RequestContext context, String id) {
  if (context.request.method != HttpMethod.put) {
    return Future.value(methodNotAllowed());
  }
  return rejectPeminjaman(context, id);
}