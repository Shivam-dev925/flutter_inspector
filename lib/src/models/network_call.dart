/// Represents a network request/response pair
class NetworkCall {
  final String id;
  final String method;
  final String url;
  final Map<String, String>? requestHeaders;
  final dynamic requestBody;
  final DateTime requestTime;

  int? statusCode;
  String? statusMessage;
  Map<String, String>? responseHeaders;
  dynamic responseBody;
  DateTime? responseTime;
  String? error;

  NetworkCall({
    required this.id,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    DateTime? requestTime,
  }) : requestTime = requestTime ?? DateTime.now();

  /// Duration of the request in milliseconds
  int? get duration {
    if (responseTime == null) return null;
    return responseTime!.difference(requestTime).inMilliseconds;
  }

  /// Whether the request was successful (2xx status code)
  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;

  /// Whether the request failed
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);

  /// Whether the request is still pending
  bool get isPending => responseTime == null && error == null;

  /// Complete the request with a response
  void complete({
    required int statusCode,
    String? statusMessage,
    Map<String, String>? responseHeaders,
    dynamic responseBody,
  }) {
    this.statusCode = statusCode;
    this.statusMessage = statusMessage;
    this.responseHeaders = responseHeaders;
    this.responseBody = responseBody;
    responseTime = DateTime.now();
  }

  /// Mark the request as failed
  void fail(String error) {
    this.error = error;
    responseTime = DateTime.now();
  }
}
