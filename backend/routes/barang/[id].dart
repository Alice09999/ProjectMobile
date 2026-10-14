import 'package:dart_frog/dart_frog.dart';

import '../../lib/src/api.dart';

// Perhatikan: tambahkan ', String id' di dalam kurung
Future<Response> onRequest(RequestContext context, String id) {
  switch (context.request.method) {
    case HttpMethod.put:
      return updateBarang(context, id);
    case HttpMethod.delete:
      return deleteBarang(context, id);
    default:
      return Future.value(methodNotAllowed());
  }
}