import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:rhttp/rhttp.dart' as rhttp;
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/log.dart';
import 'package:venera/network/cache.dart';
import 'package:venera/network/proxy.dart';
import 'package:http_parser/http_parser.dart';

import '../foundation/app.dart';
import 'cloudflare.dart';
import 'cookie_jar.dart';

export 'package:dio/dio.dart';

/// 自定义Transformer，用于处理格式不正确的Content-Type头部
class SafeTransformer extends Transformer {
  @override
  Future<String> transformRequest(RequestOptions options) async {
    var data = options.data;
    if (data != null) {
      if (data is Map || data is List) {
        return jsonEncode(data);
      } else {
        return data.toString();
      }
    }
    return '';
  }

  @override
  Future transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    // 对于stream和bytes类型的请求，不进行转换，直接使用默认的Transformer
    if (options.responseType == ResponseType.stream ||
        options.responseType == ResponseType.bytes) {
      // 使用Dio的背景Transformer处理
      return BackgroundTransformer().transformResponse(options, responseBody);
    }

    // 获取响应数据，添加大小限制防止内存溢出
    var bytes = <int>[];
    const maxResponseSize = 50 * 1024 * 1024; // 50MB限制
    int totalBytes = 0;

    await for (var chunk in responseBody.stream) {
      totalBytes += chunk.length;

      // 检查是否超过大小限制
      if (totalBytes > maxResponseSize) {
        Log.warning(
          "Network",
          "Response size exceeded limit (${totalBytes} bytes > ${maxResponseSize} bytes), truncating response",
        );
        break;
      }

      bytes.addAll(chunk);
    }
    var responseData = Uint8List.fromList(bytes);

    // 如果没有数据，直接返回
    if (responseData.isEmpty) {
      return null;
    }

    // 对于plain类型的请求（JavaScript引擎），直接返回字符串
    if (options.responseType == ResponseType.plain) {
      try {
        return utf8.decode(responseData, allowMalformed: true);
      } catch (e) {
        Log.warning("Network", "Failed to decode response as UTF-8: $e");
        return responseData;
      }
    }

    // 检查Content-Type头部
    var contentType = responseBody.headers['content-type']?.first;

    // 如果Content-Type存在但格式不正确，尝试修复
    if (contentType != null) {
      // 移除末尾多余的分号和空格
      contentType = contentType.trim();
      if (contentType.endsWith(';')) {
        contentType = contentType.substring(0, contentType.length - 1).trim();
      }

      try {
        // 尝试解析修复后的Content-Type
        var mediaType = MediaType.parse(contentType);

        // 根据媒体类型处理响应数据
        if (mediaType.mimeType == 'application/json' ||
            mediaType.mimeType == 'text/json') {
          try {
            var jsonString = utf8.decode(responseData, allowMalformed: true);
            return jsonDecode(jsonString);
          } catch (e) {
            Log.warning("Network", "Failed to decode JSON response: $e");
            return utf8.decode(responseData, allowMalformed: true);
          }
        } else if (mediaType.type == 'text') {
          return utf8.decode(responseData, allowMalformed: true);
        }
      } catch (e) {
        Log.warning(
          "Network",
          "Failed to parse Content-Type '$contentType': $e",
        );
        // 如果Content-Type解析失败，尝试根据数据内容推断类型
        try {
          var textData = utf8.decode(responseData, allowMalformed: true);
          // 对于非plain类型的请求，尝试解析为JSON
          if (textData.trim().startsWith('{') ||
              textData.trim().startsWith('[')) {
            return jsonDecode(textData);
          }
          return textData;
        } catch (e2) {
          Log.warning("Network", "Failed to decode response as text: $e2");
          return responseData;
        }
      }
    }

    // 如果没有Content-Type头部，尝试根据数据内容推断
    try {
      var textData = utf8.decode(responseData, allowMalformed: true);
      // 对于非plain类型的请求，尝试解析为JSON
      if (textData.trim().startsWith('{') || textData.trim().startsWith('[')) {
        return jsonDecode(textData);
      }
      return textData;
    } catch (e) {
      // 如果无法解码为文本，返回原始字节数据
      return responseData;
    }
  }
}

class MyLogInterceptor implements Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.error(
      "Network",
      "${err.requestOptions.method} ${err.requestOptions.path}\n$err\n${err.response?.data.toString()}",
    );

    // 检查是否是媒体类型解析错误
    if (err.toString().contains("Failed to parse the media type") ||
        err.toString().contains("not a JSON MIME type")) {
      Log.warning(
        "Network",
        "Media type parsing error detected, using SafeTransformer should handle this",
      );
      err = err.copyWith(
        message:
            "Media type parsing error: "
            "The server returned an invalid Content-Type header. "
            "This has been handled automatically.",
      );
    }

    switch (err.type) {
      case DioExceptionType.badResponse:
        var statusCode = err.response?.statusCode;
        if (statusCode != null) {
          err = err.copyWith(
            message:
                "Invalid Status Code: $statusCode. "
                "${_getStatusCodeInfo(statusCode)}",
          );
        }
      case DioExceptionType.connectionTimeout:
        err = err.copyWith(message: "Connection Timeout");
      case DioExceptionType.receiveTimeout:
        err = err.copyWith(
          message:
              "Receive Timeout: "
              "This indicates that the server is too busy to respond",
        );
      case DioExceptionType.unknown:
        if (err.toString().contains("Connection terminated during handshake")) {
          err = err.copyWith(
            message:
                "Connection terminated during handshake: "
                "This may be caused by the firewall blocking the connection "
                "or your requests are too frequent.",
          );
        } else if (err.toString().contains("Connection reset by peer")) {
          err = err.copyWith(
            message:
                "Connection reset by peer: "
                "The error is unrelated to app, please check your network.",
          );
        }
      default:
        {}
    }
    handler.next(err);
  }

  static const errorMessages = <int, String>{
    400: "The Request is invalid.",
    401: "The Request is unauthorized.",
    403: "No permission to access the resource. Check your account or network.",
    404: "Not found.",
    429: "Too many requests. Please try again later.",
  };

  String _getStatusCodeInfo(int? statusCode) {
    if (statusCode != null && statusCode >= 500) {
      return "This is server-side error, please try again later. "
          "Do not report this issue.";
    } else {
      return errorMessages[statusCode] ?? "";
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    var headers = response.headers.map.map(
      (key, value) => MapEntry(
        key.toLowerCase(),
        value.length == 1 ? value.first : value.toString(),
      ),
    );
    headers.remove("cookie");
    String content;
    if (response.data is List<int>) {
      try {
        content = utf8.decode(response.data, allowMalformed: false);
      } catch (e) {
        content = "<Bytes>\nlength:${response.data.length}";
      }
    } else {
      content = response.data.toString();
    }
    Log.addLog(
      (response.statusCode != null && response.statusCode! < 400)
          ? LogLevel.info
          : LogLevel.error,
      "Network",
      "Response ${response.realUri.toString()} ${response.statusCode}\n"
          "headers:\n$headers\n$content",
    );
    handler.next(response);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Log.info(
      "Network",
      "${options.method} ${options.uri}\n"
          "headers:\n${options.headers}\n"
          "data:\n${options.data}",
    );
    options.connectTimeout = const Duration(seconds: 15);
    options.receiveTimeout = const Duration(seconds: 15);
    options.sendTimeout = const Duration(seconds: 15);
    handler.next(options);
  }
}

class AppDio with DioMixin {
  AppDio([BaseOptions? options]) {
    this.options = options ?? BaseOptions();
    httpClientAdapter = RHttpAdapter();
    // 使用自定义的SafeTransformer来处理格式不正确的Content-Type
    transformer = SafeTransformer();
    if (App.isInitialized) {
      interceptors.add(CookieManagerSql(SingleInstanceCookieJar.instance!));
      interceptors.add(NetworkCacheManager());
      interceptors.add(CloudflareInterceptor());
      interceptors.add(MyLogInterceptor());
    }
  }

  static final Map<String, bool> _requests = {};

  @override
  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (options?.headers?['prevent-parallel'] == 'true') {
      while (_requests.containsKey(path)) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      _requests[path] = true;
      options!.headers!.remove('prevent-parallel');
    }
    try {
      return super.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } finally {
      if (_requests.containsKey(path)) {
        _requests.remove(path);
      }
    }
  }
}

class RHttpAdapter implements HttpClientAdapter {
  Future<rhttp.ClientSettings> get settings async {
    var proxy = await getProxy();

    return rhttp.ClientSettings(
      proxySettings: proxy == null
          ? const rhttp.ProxySettings.noProxy()
          : rhttp.ProxySettings.proxy(proxy),
      redirectSettings: const rhttp.RedirectSettings.limited(5),
      timeoutSettings: const rhttp.TimeoutSettings(
        connectTimeout: Duration(seconds: 15),
        keepAliveTimeout: Duration(seconds: 60),
        keepAlivePing: Duration(seconds: 30),
      ),
      throwOnStatusCode: false,
      dnsSettings: rhttp.DnsSettings.static(overrides: _getOverrides()),
      tlsSettings: rhttp.TlsSettings(
        sni: appdata.settings['sni'] != false,
        verifyCertificates: appdata.settings['ignoreBadCertificate'] != true,
      ),
    );
  }

  static Map<String, List<String>> _getOverrides() {
    if (!appdata.settings['enableDnsOverrides'] == true) {
      return {};
    }
    var config = appdata.settings["dnsOverrides"];
    var result = <String, List<String>>{};
    if (config is Map) {
      for (var entry in config.entries) {
        if (entry.key is String && entry.value is String) {
          result[entry.key] = [entry.value];
        }
      }
    }
    return result;
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.headers['User-Agent'] == null &&
        options.headers['user-agent'] == null) {
      options.headers['User-Agent'] = "venera/v${App.version}";
    }

    var res = await rhttp.Rhttp.request(
      method: rhttp.HttpMethod(options.method),
      url: options.uri.toString(),
      settings: await settings,
      expectBody: rhttp.HttpExpectBody.stream,
      body: requestStream == null ? null : rhttp.HttpBody.stream(requestStream),
      headers: rhttp.HttpHeaders.rawMap(
        Map.fromEntries(
          options.headers.entries.map(
            (e) => MapEntry(e.key, e.value.toString().trim()),
          ),
        ),
      ),
    );
    if (res is! rhttp.HttpStreamResponse) {
      throw Exception("Invalid response type: ${res.runtimeType}");
    }
    var headers = <String, List<String>>{};
    for (var entry in res.headers) {
      var key = entry.$1.toLowerCase();
      headers[key] ??= [];
      headers[key]!.add(entry.$2);
    }
    return ResponseBody(
      res.body,
      res.statusCode,
      statusMessage: _getStatusMessage(res.statusCode),
      isRedirect: false,
      headers: headers,
    );
  }

  static String _getStatusMessage(int statusCode) {
    return switch (statusCode) {
      200 => "OK",
      201 => "Created",
      202 => "Accepted",
      204 => "No Content",
      206 => "Partial Content",
      301 => "Moved Permanently",
      302 => "Found",
      400 => "Invalid Status Code 400: The Request is invalid.",
      401 => "Invalid Status Code 401: The Request is unauthorized.",
      403 =>
        "Invalid Status Code 403: No permission to access the resource. Check your account or network.",
      404 => "Invalid Status Code 404: Not found.",
      429 =>
        "Invalid Status Code 429: Too many requests. Please try again later.",
      _ => "Invalid Status Code $statusCode",
    };
  }
}
