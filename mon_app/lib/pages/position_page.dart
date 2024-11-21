import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sector.dart';
import '../providers/event_notifier.dart';
import 'shift_management_page.dart';

class PositionPage extends ConsumerStatefulWidget {
  final Sector sector;

  const PositionPage({
    required this.sector,
    super.key,
  });

  @override
  ConsumerState<PositionPage> createState() => _PositionPageState();
}

class _PositionPageState extends ConsumerState<PositionPage> {
  final _formKey = GlobalKey<FormState>();
  final _positionNameController = TextEditingController();

  @override
  void dispose() {
    _positionNameController.dispose();
    super.dispose();
  }

  void _addPosition() {
    if (_formKey.currentState!.validate()) {
      ref.read(eventProvider.notifier).addPosition(
            widget.sector.id,
            _positionNameController.text,
          );
      _positionNameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider);
    if (event == null) return const SizedBox.shrink();

    // Trouve le secteur actuel dans l'événement pour avoir les données à jour
    final currentSector = event.sectors.firstWhere(
      (s) => s.id == widget.sector.id,
      orElse: () => widget.sector,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Postes - ${currentSector.name}'),
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
                      controller: _positionNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du poste',
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
                    onPressed: _addPosition,
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentSector.positions.length,
              itemBuilder: (context, index) {
                final position = currentSector.positions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    title: Text(position.name),
                    subtitle: Text(
                      '${position.shifts.length} shifts configurés',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.schedule),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShiftManagementPage(
                                  sectorId: currentSector.id,
                                  position: position,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Gérer les shifts',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            ref.read(eventProvider.notifier).removePosition(
                                  currentSector.id,
                                  position.id,
                                );
                          },
                          tooltip: 'Supprimer le poste',
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