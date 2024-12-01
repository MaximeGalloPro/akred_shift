import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/event_notifier.dart';
import '../services/ai_service_manager.dart';
import '../widgets/contextual_ai_interface.dart';
import 'position_page.dart';

class SectorPage extends ConsumerStatefulWidget {
  const SectorPage({super.key});

  @override
  ConsumerState<SectorPage> createState() => _SectorPageState();
}

class _SectorPageState extends ConsumerState<SectorPage> {
  final _formKey = GlobalKey<FormState>();
  final _sectorNameController = TextEditingController();
  bool _showAIInterface = false;

  @override
  void dispose() {
    _sectorNameController.dispose();
    super.dispose();
  }

  void _addSector() {
    if (_formKey.currentState!.validate()) {
      ref.read(eventProvider.notifier).addSector(_sectorNameController.text);
      _sectorNameController.clear();
    }
  }

  void _onAICommandProcessed(Map<String, dynamic> response) {
    if (response['action'] == 'update_event') {
      final sectors = response['data']['sectors'] as List;
      for (final sectorData in sectors) {
        // Si on a une opération explicite
        if (sectorData.containsKey('operation')) {
          final operation = sectorData['operation'] as String;
          final name = sectorData['name'] as String;

          switch (operation) {
            case 'add':
              print('Ajout du secteur (via operation): $name'); // Debug
              ref.read(eventProvider.notifier).addSector(name);
              break;
            case 'remove':
              final event = ref.read(eventProvider);
              if (event != null) {
                final sector = event.sectors.where((s) => s.name == name).firstOrNull;
                if (sector != null) {
                  ref.read(eventProvider.notifier).removeSector(sector.id);
                }
              }
              break;
            case 'rename':
              final newName = sectorData['newName'] as String;
              ref.read(eventProvider.notifier).renameSector(name, newName);
              break;
          }
        }
        // Sinon, traiter comme un ajout simple
        else if (sectorData.containsKey('name')) {
          print('Ajout du secteur (simple): ${sectorData['name']}'); // Debug
          ref.read(eventProvider.notifier).addSector(sectorData['name']);
        }

        // Vérifions l'état après modification
        final event = ref.read(eventProvider);
        print('Secteurs après modification: ${event?.sectors.map((s) => s.name).join(', ')}'); // Debug
      }

      // Notification visuelle
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secteurs mis à jour'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Force le rebuild du widget
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider);
    if (event == null) return const Scaffold(body: Center(child: Text('Aucun événement')));

    // Préparer les données de contexte pour l'IA
    final contextData = {
      'sectors': event.sectors.map((s) => s.name).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des secteurs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              setState(() => _showAIInterface = !_showAIInterface);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showAIInterface)
            ContextualAIInterface(
              aiContext: AIContext.sectorManagement,
              contextData: contextData,
              onCommandProcessed: _onAICommandProcessed,
              hintText: 'Décrivez les secteurs à ajouter...',
              testCommand: "Ajoute un secteur restauration et un secteur technique",
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sectorNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du secteur',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _addSector,
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: event.sectors.isEmpty
                ? const Center(child: Text('Aucun secteur créé'))
                : ListView.builder(
              itemCount: event.sectors.length,
              itemBuilder: (context, index) {
                final sector = event.sectors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    title: Text(sector.name),
                    subtitle: Text(
                      '${sector.positions.length} postes configurés',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PositionPage(sector: sector),
                              ),
                            );
                          },
                          tooltip: 'Gérer les postes',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            ref.read(eventProvider.notifier).removeSector(sector.id);
                          },
                          tooltip: 'Supprimer le secteur',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}