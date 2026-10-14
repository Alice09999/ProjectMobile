import 'package:dart_frog/dart_frog.dart';

import '../../lib/src/api.dart';

Future<Response> onRequest(RequestContext context) {
  switch (context.request.method) {
    case HttpMethod.get:
      return listBarang(context);
    case HttpMethod.post:
      return createBarang(context);
    default:
      return Future.value(methodNotAllowed());
  }
}
