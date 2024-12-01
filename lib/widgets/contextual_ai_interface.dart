import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service_manager.dart';

class ContextualAIInterface extends ConsumerStatefulWidget {
  final AIContext aiContext;
  final Map<String, dynamic>? contextData;
  final Function(Map<String, dynamic>) onCommandProcessed;
  final String hintText;
  final String? testCommand;

  const ContextualAIInterface({
    super.key,
    required this.aiContext,
    this.contextData,
    required this.onCommandProcessed,
    required this.hintText,
    this.testCommand,
  });

  @override
  ConsumerState<ContextualAIInterface> createState() => _ContextualAIInterfaceState();
}

class _ContextualAIInterfaceState extends ConsumerState<ContextualAIInterface> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _commandController = TextEditingController();
  bool _isListening = false;
  String _status = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
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
      _status = 'Écoute en cours...';
    });

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _commandController.text = result.recognizedWords;
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

  Future<void> _processCommand() async {
    if (_isProcessing) return;
    final command = _commandController.text.trim();
    if (command.isEmpty) {
      setState(() => _status = 'Veuillez entrer une commande');
      return;
    }

    setState(() {
      _status = 'Analyse en cours...';
      _isProcessing = true;
    });

    try {
      final aiResponse = await AIServiceManager.interpretCommand(
        command,
        widget.aiContext,
        contextData: widget.contextData,
      );

      if (aiResponse.containsKey('error')) {
        throw Exception(aiResponse['error']);
      }

      setState(() => _status = 'Commande traitée avec succès !');
      widget.onCommandProcessed(aiResponse);
      _commandController.clear();

    } catch (e) {
      setState(() => _status = 'Erreur: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _fillTestCommand() {
    if (widget.testCommand != null) {
      _commandController.text = widget.testCommand!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _status,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commandController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _commandController.clear(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.testCommand != null)
                ElevatedButton(
                  onPressed: _fillTestCommand,
                  child: const Text('Commande test'),
                ),
              ElevatedButton(
                onPressed: _processCommand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Envoyer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isProcessing)
            const CircularProgressIndicator()
          else
            FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            ),
          if (_isListening)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Parlez maintenant...',
                  style: TextStyle(fontStyle: FontStyle.italic)
              ),
            ),
        ],
      ),
    );
  }
}