import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'message': 'Method tidak diizinkan.'});
  }
  return Response.json(body: {'status': 'ok'});
}
