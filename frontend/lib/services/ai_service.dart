import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api_client.dart';

class AIService {
  Future<String> askAI(String prompt, String transactionData) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/chatbot/ask',
        body: jsonEncode({
          'message': prompt,
          'transactions': transactionData,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ??
            "I'm sorry, I couldn't process your request right now.";
      }

      return "⚠️ Backend Error (${response.statusCode}): Please check that the backend server is running and your API key is configured.";
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return "⚠️ Connection timed out. Please ensure the backend server is running and reachable on your network.";
      }
      return "⚠️ An unexpected error occurred: ${e.toString()}";
    }
  }
}
