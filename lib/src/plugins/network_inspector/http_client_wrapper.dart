import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dev_panel/src/models/network_call.dart';

/// HTTP client wrapper that intercepts requests for DevPanel
class DevPanelHttpClient extends http.BaseClient {
  final http.Client _inner;
  final void Function(NetworkCall) onCall;

  DevPanelHttpClient(this._inner, this.onCall);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final callId = DateTime.now().millisecondsSinceEpoch.toString();

    // Read request body if available
    String? requestBody;
    if (request is http.Request) {
      requestBody = request.body;
    }

    // Create initial call record
    final call = NetworkCall(
      id: callId,
      method: request.method,
      url: request.url.toString(),
      requestHeaders: request.headers,
      requestBody: requestBody,
    );

    onCall(call);

    try {
      final response = await _inner.send(request);

      // Read response body
      final responseBytes = await response.stream.toBytes();
      final responseBody = utf8.decode(responseBytes);

      // Update call with response
      call.complete(
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        responseHeaders: response.headers,
        responseBody: responseBody,
      );

      onCall(call);

      // Return a new response with the read body
      return http.StreamedResponse(
        Stream.value(responseBytes),
        response.statusCode,
        contentLength: responseBytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      call.fail(e.toString());
      onCall(call);
      rethrow;
    }
  }
}
