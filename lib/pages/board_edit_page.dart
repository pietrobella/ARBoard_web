import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import '../widgets/navbar.dart';
import '../models/board.dart';
import '../models/crop_schematic.dart';
import '../models/user_manual.dart';
import '../models/label.dart';
import '../services/board_service.dart';
import '../router/app_router.dart';

/// Board Edit Page
///
/// This page allows editing a specific board.
/// Displays board information and allows viewing schematics and user manuals.
class BoardEditPage extends StatefulWidget {
  final String boardName;

  const BoardEditPage({super.key, required this.boardName});

  @override
  State<BoardEditPage> createState() => _BoardEditPageState();
}

class _BoardEditPageState extends State<BoardEditPage> {
  final BoardService _boardService = BoardService();

  bool _isLoading = true;
  String? _error;
  Board? _board;
  List<CropSchematic> _schematics = [];
  List<UserManual> _manuals = [];
  List<Label> _labels = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 1. Fetch all boards to find the one with the matching name
      final boards = await _boardService.getBoards();

      final board = boards.firstWhere(
        (b) => b.name == widget.boardName,
        orElse: () => Board(id: '', name: ''),
      );

      if (board.id.isEmpty) {
        setState(() {
          _board = null;
          _isLoading = false;
        });
        return;
      }

      // 2. Fetch schematics, manuals, and labels in parallel
      final results = await Future.wait([
        _boardService.getCropSchematics(board.id),
        _boardService.getUserManuals(board.id),
        _boardService.getLabels(board.id),
      ]);

      if (mounted) {
        setState(() {
          _board = board;
          _schematics = results[0] as List<CropSchematic>;
          _manuals = results[1] as List<UserManual>;
          _labels = results[2] as List<Label>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBoard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione board'),
        content: Text(
          'Sei sicuro di voler eliminare la board "${_board!.name}" e tutti i suoi dati? Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _boardService.deleteBoard(_board!.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Board eliminata')));
          context.go(AppRoutes.boardManagement);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSchematic(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo schematico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _boardService.deleteCropSchematic(id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Schematico eliminato')));
          _loadData(); // Reload data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteManual(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo manuale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _boardService.deleteUserManual(id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Manuale eliminato')));
          _loadData(); // Reload data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteLabel(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questa label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _boardService.deleteLabel(id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Label eliminata')));
          _loadData(); // Reload data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
          );
        }
      }
    }
  }

  Future<void> _showLabelDetails(Label label) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final details = await _boardService.getLabelDetails(label.id, _board!.id);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading

        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    if (label.description != null) ...[
                      const SizedBox(height: 8),
                      Text(label.description!),
                    ],
                    const SizedBox(height: 24),

                    if (label.sublabels.isNotEmpty) ...[
                      Text(
                        'Sublabels:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: label.sublabels.map((sl) {
                          return Chip(label: Text(sl.name));
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Associations:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if ((details['items'] as List).isEmpty)
                      const Text('No associations')
                    else
                      ..._buildAssociationList(details['items'] as List),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento dettagli: $e')),
        );
      }
    }
  }

  List<Widget> _buildAssociationList(List<dynamic> items) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var item in items) {
      final componentName = item['component_name'];
      if (!grouped.containsKey(componentName)) {
        grouped[componentName] = [];
      }
      grouped[componentName]!.add({
        'pin_name': item['pin_name'],
        'sublabel_name': item['sublabel_name'],
      });
    }

    return grouped.entries.map((entry) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.memory, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...entry.value.map((pin) {
                return Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('${pin['pin_name']}'),
                      if (pin['sublabel_name'] != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(pin['sublabel_name']),
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 11),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showSchematicPreview(CropSchematic schematic) {
    if (schematic.filePng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Immagine non disponibile')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Image.memory(
                base64Decode(schematic.filePng!),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualPreview(UserManual manual) async {
    // Show loading while fetching the full PDF
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fullManual = await _boardService.getUserManualById(manual.id);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        if (fullManual.filePdf == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PDF non disponibile')));
          return;
        }

        showDialog(
          context: context,
          builder: (context) =>
              _PdfPreviewDialog(pdfData: base64Decode(fullManual.filePdf!)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento del PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const NavBar(), body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Errore nel caricamento',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.boardManagement),
                child: const Text('Torna a Board Management'),
              ),
            ],
          ),
        ),
      );
    }

    if (_board == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Board non trovata',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'La board "${widget.boardName}" non esiste',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.boardManagement),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Torna a Board Management'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                const Icon(Icons.edit, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Modifica Board',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _board!.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${_board!.id}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Schematics Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schematics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push(
                    AppRoutes.buildNewSchematicRoute(widget.boardName),
                  );
                  _loadData(); // Refresh data on return
                },
                icon: const Icon(Icons.add),
                label: const Text('NEW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: Text('Lista Schematics (${_schematics.length})'),
              children: _schematics.isEmpty
                  ? [const ListTile(title: Text('Nessuno schematico presente'))]
                  : _schematics.map((schematic) {
                      return ListTile(
                        leading: const Icon(Icons.image),
                        title: Text(
                          '${schematic.function} - ${schematic.side ?? "N/A"}',
                        ),
                        subtitle: Text('ID: ${schematic.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Anteprima',
                              onPressed: () => _showSchematicPreview(schematic),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Elimina',
                              onPressed: () => _deleteSchematic(schematic.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // User Manuals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Manuals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push(
                    AppRoutes.buildNewUserManualRoute(widget.boardName),
                  );
                  _loadData(); // Refresh data on return
                },
                icon: const Icon(Icons.add),
                label: const Text('NEW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: Text('Lista User Manuals (${_manuals.length})'),
              children: _manuals.isEmpty
                  ? [const ListTile(title: Text('Nessun manuale presente'))]
                  : _manuals.map((manual) {
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text('Manuale ID: ${manual.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Anteprima',
                              onPressed: () => _showManualPreview(manual),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Elimina',
                              onPressed: () => _deleteManual(manual.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Labels Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Labels', style: Theme.of(context).textTheme.titleMedium),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push(
                    AppRoutes.buildNewLabelRoute(widget.boardName),
                  );
                  _loadData(); // Refresh data on return
                },
                icon: const Icon(Icons.add),
                label: const Text('NEW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: Text('Lista Labels (${_labels.length})'),
              children: _labels.isEmpty
                  ? [const ListTile(title: Text('Nessuna label presente'))]
                  : _labels.map((label) {
                      return ListTile(
                        leading: const Icon(Icons.label),
                        title: Text(label.name),
                        subtitle: label.description != null
                            ? Text(
                                label.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Dettagli',
                              onPressed: () => _showLabelDetails(label),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Elimina',
                              onPressed: () => _deleteLabel(label.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),

          const SizedBox(height: 48),

          Center(
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.boardManagement),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Torna a Board Management'),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _deleteBoard,
              icon: const Icon(Icons.delete_forever),
              label: const Text('ELIMINA BOARD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfPreviewDialog extends StatefulWidget {
  final Uint8List pdfData;

  const _PdfPreviewDialog({required this.pdfData});

  @override
  State<_PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<_PdfPreviewDialog> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openData(widget.pdfData),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          PdfView(controller: _pdfController, scrollDirection: Axis.vertical),
          Positioned(
            right: 8,
            top: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
