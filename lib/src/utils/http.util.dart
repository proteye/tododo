import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

class Http {
  static const String GET = 'get';
  static const String POST = 'post';

  static get(String url, Function callback,
      {Map<String, String> params,
      Map<String, String> headers,
      Function errorCallback}) async {
    if (!url.startsWith('http')) {
      url = Config.HTTP_HOST + Config.BASE_URL + url;
    }

    if (params != null && params.isNotEmpty) {
      StringBuffer sb = new StringBuffer('?');
      params.forEach((key, value) {
        sb.write('$key=$value&');
      });
      String paramStr = sb.toString();
      paramStr = paramStr.substring(0, paramStr.length - 1);
      url += paramStr;
    }

    return await request(url, callback,
        method: GET, headers: headers, errorCallback: errorCallback);
  }

  static post(String url, Function callback,
      {Map<String, dynamic> params,
      Map<String, String> headers,
      Function errorCallback}) async {
    if (!url.startsWith('http')) {
      url = Config.HTTP_HOST + Config.BASE_URL + url;
    }

    return await request(url, callback,
        method: POST,
        headers: headers,
        params: params,
        errorCallback: errorCallback);
  }

  static Future request(String url, Function callback,
      {String method,
      Map<String, String> headers,
      Map<String, dynamic> params,
      Function errorCallback}) async {
    String errorCode;
    String msg;
    bool success;
    int status;
    Map<String, dynamic> result;

    try {
      Map<String, String> headerMap = headers == null ? new Map() : headers;
      Map<String, dynamic> paramMap = params == null ? new Map() : params;

      headerMap['Content-Type'] = 'text/html; charset=utf-8';

      http.Response res;

      if (method == POST) {
        res = await http.post(
          url,
          headers: headerMap,
          body: json.encode(paramMap),
          encoding: Encoding.getByName('utf-8'),
        );
      } else {
        res = await http.get(
          url,
          headers: headerMap,
        );
      }

      if (res.statusCode > 400) {
        msg = 'Network request error: ' + res.statusCode.toString();
        handleError(errorCallback, msg);
        return {
          'errorMessage': msg,
          'errorCode': 'NETWORK_ERROR',
          'success': false,
          'status': res.statusCode
        };
      }

      String body = utf8.decode(res.bodyBytes);

      Map<String, dynamic> map = json.decode(body);
      status = res.statusCode;
      errorCode = map['error'];
      success = map['success'];
      msg = map['message'];
      result = {
        'data': body,
        'status': status,
        'success': success,
        'message': msg
      };

      if (status == 400 || status < 200) {
        handleError(errorCallback, msg);
        return {
          'errorMessage': msg,
          'errorCode': errorCode,
          'success': false,
          'status': status
        };
      }

      if (callback != null) {
        callback(result);
      }

      return result;
    } catch (e) {
      handleError(errorCallback, e.toString());
      return {
        'errorMessage': e.toString(),
        'errorCode': 'EXCEPTION_ERROR',
        'success': false,
        'status': 0
      };
    }
  }

  static void handleError(Function errorCallback, String errorMsg) {
    if (errorCallback != null) {
      errorCallback(errorMsg);
    }

    print('errorMsg: ' + errorMsg);
  }
}
