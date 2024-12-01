import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/event_notifier.dart';
import '../services/ai_service.dart';
import 'package:intl/intl.dart';

class VoiceInterfacePage extends ConsumerStatefulWidget {
  const VoiceInterfacePage({super.key});

  @override
  ConsumerState<VoiceInterfacePage> createState() => _VoiceInterfacePageState();
}

class _VoiceInterfacePageState extends ConsumerState<VoiceInterfacePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _transcription = '';
  String _lastCommand = '';
  String _status = '';
  bool _isProcessing = false;

  // Texte de test par défaut
  final String _testCommand = "Crée un événement du 15 au 20 décembre avec un secteur bar qui contient un poste de barman avec des shifts de matin de 9h à 17h et de soir de 17h à 23h";

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
          if (_transcription.isNotEmpty) {
            _processCommand(_transcription);
          }
        }
      },
      onError: (error) => setState(() {
        _status = 'Erreur: $error';
        _isListening = false;
      }),
    );

    if (!available) {
      setState(() => _status = "Le microphone n'est pas disponible");
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _transcription = '';
      _status = 'Écoute en cours...';
    });

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _transcription = result.recognizedWords;
            });
          },
          localeId: 'fr_FR',
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processCommand(String command) async {
    if (_isProcessing) return;

    setState(() {
      _lastCommand = command;
      _status = 'Analyse en cours...';
      _isProcessing = true;
    });

    try {
      final aiResponse = await AIService.interpretCommand(command);

      if (aiResponse.containsKey('error')) {
        throw Exception(aiResponse['error']);
      }

      if (aiResponse['action'] == 'create_event') {
        final data = aiResponse['data'];

        final startDate = DateTime.parse(data['startDate']);
        final endDate = DateTime.parse(data['endDate']);

        ref.read(eventProvider.notifier).initEvent(
          'voice-event-${const Uuid().v4()}',
          startDate,
          endDate,
        );

        for (final sector in data['sectors']) {
          ref.read(eventProvider.notifier).addSector(sector['name']);

          for (final position in sector['positions']) {
            ref.read(eventProvider.notifier).addPosition(
              sector['name'],
              position['name'],
            );

            for (final shift in position['shifts']) {
              final shiftDate = startDate;
              final startTime = TimeOfDay.fromDateTime(
                  DateFormat('HH:mm').parse(shift['startTime'])
              );
              final endTime = TimeOfDay.fromDateTime(
                  DateFormat('HH:mm').parse(shift['endTime'])
              );

              ref.read(eventProvider.notifier).addShift(
                sector['name'],
                position['name'],
                shift['label'],
                DateTime(
                  shiftDate.year,
                  shiftDate.month,
                  shiftDate.day,
                  startTime.hour,
                  startTime.minute,
                ),
                DateTime(
                  shiftDate.year,
                  shiftDate.month,
                  shiftDate.day,
                  endTime.hour,
                  endTime.minute,
                ),
              );
            }
          }
        }

        setState(() => _status = 'Événement créé avec succès !');

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        throw Exception('Action non reconnue');
      }
    } catch (e) {
      setState(() => _status = 'Erreur: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Vocal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? 'Écoute en cours...' : 'Appuyez pour parler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // Bouton de test ajouté
            ElevatedButton(
              onPressed: () => _processCommand(_testCommand),
              child: const Text('Tester avec commande par défaut'),
            ),
            const SizedBox(height: 20),
            if (_transcription.isNotEmpty) ...[
              const Text('Transcription:'),
              Text(
                _transcription,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            if (_lastCommand.isNotEmpty && !_isListening) ...[
              const SizedBox(height: 20),
              const Text('Dernière commande :'),
              Text(_lastCommand),
            ],
            const Spacer(),
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              FloatingActionButton.large(
                onPressed: _isListening ? _stopListening : _startListening,
                child: Icon(_isListening ? Icons.mic_off : Icons.mic),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}