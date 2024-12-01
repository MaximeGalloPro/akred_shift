import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AIService {
  static String get _apiKey => dotenv.get('OPENAI_API_KEY');
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static String get systemPrompt => '''
Tu es un assistant spécialisé dans la création d'événements. Tu dois analyser les demandes vocales et les transformer en commandes structurées JSON.

Fonctions disponibles :
1. Créer un événement (dates début/fin)
2. Ajouter des secteurs
3. Ajouter des positions par secteur
4. Ajouter des shifts par position

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

  static Future<Map<String, dynamic>> interpretCommand(String command) async {
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
            {'role': 'system', 'content': systemPrompt},
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