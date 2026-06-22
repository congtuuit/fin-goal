import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/services/ai_service.dart';

class DirectClientAiService implements AiService {
  final SharedPreferences _prefs;
  
  static const keyProvider = 'ai_provider';
  static const keyApiKey = 'ai_api_key';
  static const keyModel = 'ai_model';

  const DirectClientAiService(this._prefs);

  @override
  Future<String> generateScenarioSimulation(String prompt) async {
    final provider = _prefs.getString(keyProvider) ?? 'gemini';
    final apiKey = _prefs.getString(keyApiKey) ?? '';
    var model = _prefs.getString(keyModel) ?? '';

    if (apiKey.trim().isEmpty) {
      throw const HttpException('API Key chưa được cấu hình. Vui lòng vào Cài đặt để điền API Key.');
    }

    if (provider == 'gemini') {
      if (model.isEmpty) model = 'gemini-1.5-flash'; // fallback default
      return _callGemini(prompt, apiKey, model);
    } else if (provider == 'openai') {
      if (model.isEmpty) model = 'gpt-4o-mini'; // fallback default
      return _callOpenAI(prompt, apiKey, model);
    } else {
      throw const HttpException('Nhà cung cấp AI không được hỗ trợ.');
    }
  }

  @override
  Future<String> chat(String prompt) => generateScenarioSimulation(prompt);

  Future<bool> testConnection(String provider, String apiKey, String model) async {
    const prompt = "Hello";
    if (apiKey.trim().isEmpty) {
      throw const HttpException('API Key chưa được cấu hình. Vui lòng điền API Key.');
    }
    
    try {
      if (provider == 'gemini') {
        if (model.isEmpty) model = 'gemini-1.5-flash'; // fallback default
        await _callGemini(prompt, apiKey, model);
      } else if (provider == 'openai') {
        if (model.isEmpty) model = 'gpt-4o-mini'; // fallback default
        await _callOpenAI(prompt, apiKey, model);
      } else {
        throw const HttpException('Nhà cung cấp AI không được hỗ trợ.');
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _callGemini(String prompt, String apiKey, String model) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'
    );
    
    final client = HttpClient();
    // Set timeout ngắn để tránh treo ứng dụng
    client.connectionTimeout = const Duration(seconds: 15);
    
    try {
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      
      final body = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      };
      
      request.write(jsonEncode(body));
      final response = await request.close();
      
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode != 200) {
        final errJson = jsonDecode(responseBody) as Map<String, dynamic>;
        final errMsg = errJson['error']?['message'] ?? 'Lỗi không xác định từ Gemini API';
        throw HttpException('Gemini API Error (${response.statusCode}): $errMsg');
      }
      
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      
      if (text == null) {
        throw const HttpException('Không nhận được phản hồi hợp lệ từ Gemini.');
      }
      
      return text;
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Lỗi kết nối Gemini: $e');
    } finally {
      client.close();
    }
  }

  Future<String> _callOpenAI(String prompt, String apiKey, String model) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    
    try {
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $apiKey');
      
      final body = {
        "model": model,
        "messages": [
          {"role": "user", "content": prompt}
        ]
      };
      
      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode != 200) {
        final errJson = jsonDecode(responseBody) as Map<String, dynamic>;
        final errMsg = errJson['error']?['message'] ?? 'Lỗi không xác định từ OpenAI API';
        throw HttpException('OpenAI API Error (${response.statusCode}): $errMsg');
      }
      
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final text = json['choices']?[0]?['message']?['content'] as String?;
      
      if (text == null) {
        throw const HttpException('Không nhận được phản hồi hợp lệ từ OpenAI.');
      }
      
      return text;
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Lỗi kết nối OpenAI: $e');
    } finally {
      client.close();
    }
  }
}
