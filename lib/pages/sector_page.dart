import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/event_notifier.dart';
import 'position_page.dart';

class SectorPage extends ConsumerStatefulWidget {
  const SectorPage({super.key});

  @override
  ConsumerState<SectorPage> createState() => _SectorPageState();
}

class _SectorPageState extends ConsumerState<SectorPage> {
  final _formKey = GlobalKey<FormState>();
  final _sectorNameController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider);
    if (event == null) return const Scaffold(body: Center(child: Text('Aucun événement')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des secteurs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
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
            child: ListView.builder(
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