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

// Prompt pour la gestion des secteurs
  static String _getSectorPrompt(List<String> existingSectors) => '''
Tu gères les secteurs d'un événement. Voici les secteurs existants: ${existingSectors.join(", ")}

Format de réponse attendu :
{
  "action": "update_event",
  "data": {
    "sectors": [
      {
        "name": "NomDuSecteur",
        "operation": "add|remove|rename",  // Type d'opération à effectuer
        "newName": "NouveauNom"           // Uniquement pour l'opération rename
      }
    ]
  }
}

Exemples:
1. Pour ajouter un secteur:
{
  "action": "update_event",
  "data": {
    "sectors": [
      {
        "name": "Restauration",
        "operation": "add"
      }
    ]
  }
}

2. Pour supprimer un secteur:
{
  "action": "update_event",
  "data": {
    "sectors": [
      {
        "name": "Bar",
        "operation": "remove"
      }
    ]
  }
}

3. Pour renommer un secteur:
{
  "action": "update_event",
  "data": {
    "sectors": [
      {
        "name": "Bar",
        "operation": "rename",
        "newName": "Zone Bar VIP"
      }
    ]
  }
}
''';

  // Prompt pour la gestion des positions d'un secteur
  static String _getPositionPrompt(String sector, List<String> existingPositions) => '''
Tu gères les positions du secteur "$sector". Positions existantes: ${existingPositions.join(", ")}

Format de réponse attendu :
{
  "action": "position_action",
  "data": {
    "operation": "add|remove|rename",
    "name": "NomDuPoste",
    "newName": "NouveauNom" // uniquement pour rename
  }
}
''';

  // Prompt pour la gestion des shifts d'une position
  static String _getShiftPrompt(String position, List<Map<String, dynamic>> existingShifts) => '''
Tu gères les shifts du poste "$position". Shifts existants: ${jsonEncode(existingShifts)}

Format de réponse attendu :
{
  "action": "shift_action",
  "data": {
    "operation": "add|remove|update",
    "label": "NomDuShift",
    "startTime": "09:00",
    "endTime": "17:00"
  }
}
''';

  static String _getPromptForContext(AIContext context, Map<String, dynamic>? contextData) {
    switch (context) {
      case AIContext.eventCreation:
        return _createEventPrompt;
      case AIContext.sectorManagement:
        return _getSectorPrompt(contextData?['sectors']?.cast<String>() ?? []);
      case AIContext.positionManagement:
        return _getPositionPrompt(
            contextData?['sector'] ?? '',
            contextData?['positions']?.cast<String>() ?? []
        );
      case AIContext.shiftManagement:
        return _getShiftPrompt(
            contextData?['position'] ?? '',
            contextData?['shifts']?.cast<Map<String, dynamic>>() ?? []
        );
    }
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