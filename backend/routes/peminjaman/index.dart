import 'package:dart_frog/dart_frog.dart';

import '../../lib/src/api.dart';

Future<Response> onRequest(RequestContext context) {
  switch (context.request.method) {
    case HttpMethod.get:
      return listPeminjaman(context);
    case HttpMethod.post:
      return createPeminjaman(context);
    default:
      return Future.value(methodNotAllowed());
  }
}
