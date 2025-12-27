import 'package:dio/dio.dart';
import 'package:flutter_dev_panel/src/models/network_call.dart';

/// Dio interceptor for capturing network calls
class DevPanelDioInterceptor extends Interceptor {
  final void Function(NetworkCall) onCall;

  DevPanelDioInterceptor(this.onCall);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final call = NetworkCall(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: options.method,
      url: options.uri.toString(),
      requestHeaders: options.headers.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      requestBody: options.data,
    );

    // Store the call ID in extra data for later retrieval
    options.extra['_devPanelCallId'] = call.id;
    onCall(call);

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final callId = response.requestOptions.extra['_devPanelCallId'] as String?;

    if (callId != null) {
      final call = NetworkCall(
        id: callId,
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        requestHeaders: response.requestOptions.headers.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
        requestBody: response.requestOptions.data,
      );

      call.complete(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage,
        responseHeaders: response.headers.map.map(
          (key, value) => MapEntry(key, value.join(', ')),
        ),
        responseBody: response.data,
      );

      onCall(call);
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final callId = err.requestOptions.extra['_devPanelCallId'] as String?;

    if (callId != null) {
      final call = NetworkCall(
        id: callId,
        method: err.requestOptions.method,
        url: err.requestOptions.uri.toString(),
        requestHeaders: err.requestOptions.headers.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
        requestBody: err.requestOptions.data,
      );

      if (err.response != null) {
        call.complete(
          statusCode: err.response!.statusCode ?? 0,
          statusMessage: err.response!.statusMessage,
          responseHeaders: err.response!.headers.map.map(
            (key, value) => MapEntry(key, value.join(', ')),
          ),
          responseBody: err.response!.data,
        );
      } else {
        call.fail(err.message ?? 'Unknown error');
      }

      onCall(call);
    }

    super.onError(err, handler);
  }
}
