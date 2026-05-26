import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../helpers/storage_helper.dart';
import 'api_endpoints.dart';

class ApiClient {

  static const Duration timeoutDuration = Duration(seconds: 20);

  /*
  -------------------------
  GET REQUEST
  -------------------------
  */

  static Future<dynamic> get(String endpoint) async {

    try {

      String? token = await StorageHelper.getToken();

      final headers = {
        "Content-Type": "application/json",
        if(token != null) "Authorization": "Bearer $token"
      };

      final url = endpoint;

      print("GET URL: $url");

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);

      print("STATUS: ${response.statusCode}");
      print("GET RESPONSE: ${response.body}");

      return _handleResponse(response);

    } on TimeoutException {

      throw Exception("Server timeout. Please try again.");

    } catch (e) {

      throw Exception("Network error: $e");

    }

  }

  /*
  -------------------------
  POST REQUEST
  -------------------------
  */

  static Future<dynamic> post(String endpoint, Map data) async {

    try {

      String? token = await StorageHelper.getToken();

      final headers = {
        "Content-Type": "application/json",
        if(token != null) "Authorization": "Bearer $token"
      };

      final url = endpoint;

      print("POST URL: $url");
      print("POST DATA: $data");

      final response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      )
          .timeout(timeoutDuration);

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      return _handleResponse(response);

    } on TimeoutException {

      throw Exception("Server timeout. Please try again.");

    } catch (e) {

      throw Exception("Network error: $e");

    }

  }

  /*
  -------------------------
  RESPONSE HANDLER
  -------------------------
  */

  static dynamic _handleResponse(http.Response response) {

    if(response.body.isEmpty){
      throw Exception("Empty server response");
    }

    final data = jsonDecode(response.body);

    if(response.statusCode == 200){
      return data;
    }

    if(response.statusCode == 401){

      StorageHelper.logout();

      throw Exception("Session expired. Please login again.");
    }

    if(response.statusCode >= 500){
      throw Exception("Server error. Please try later.");
    }

    return data;

  }

}