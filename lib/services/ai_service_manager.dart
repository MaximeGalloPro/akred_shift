import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

enum AIContext {
  eventCreation,
  sectorManagement,
  positionManagement,
  shiftManagement
}

class AIServiceManager {
  static String get _apiKey => dotenv.get('OPENAI_API_KEY');
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Prompt pour la création complète d'un événement
  static String get _createEventPrompt => '''
Tu es un assistant spécialisé dans la création d'événements. Tu dois analyser les demandes et les transformer en commandes structurées JSON.

Format de réponse attendu :
{
  "action": "create_event",
  "data": {
    "startDate": "2024-01-01",
    "endDate": "2024-01-07",
    "sectors": [
      {
        "name": "Bar",
        "positions": [
          {
            "name": "Barman",
            "shifts": [
              {
                "label": "Matin",
                "startTime": "09:00",
                "endTime": "17:00"
              }
            ]
          }
        ]
      }
    ]
  }
}
''';

  // Prompt pour la gestion des dates uniquement
  static String get _datesPrompt => '''
Tu dois analyser les demandes concernant les dates d'un événement.

Format de réponse attendu :
{
  "action": "update_event_dates",
  "data": {
    "startDate": "2024-01-01",
    "endDate": "2024-01-07"
  }
}
''';

  static String _getPromptForContext(AIContext context, Map<String, dynamic>? contextData) {
    if (contextData?.containsKey('startDate') ?? false) {
      return _createEventPrompt;
    }
    return _createEventPrompt; // Pour l'instant on retourne toujours le même prompt
  }

  static Future<Map<String, dynamic>> interpretCommand(
      String command,
      AIContext context, {
        Map<String, dynamic>? contextData,
      }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-1106-preview',
          'messages': [
            {'role': 'system', 'content': _getPromptForContext(context, contextData)},
            {'role': 'user', 'content': command},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonDecode(jsonResponse['choices'][0]['message']['content']);
        return content;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur: $e');
      return {'error': e.toString()};
    }
  }
}