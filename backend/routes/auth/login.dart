import 'package:dart_frog/dart_frog.dart';

import '../../lib/src/api.dart';

Future<Response> onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.post) {
    return Future.value(methodNotAllowed());
  }
  return login(context);
}
