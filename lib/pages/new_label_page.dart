import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/board.dart';
import '../models/component.dart';
import '../models/label.dart';
import '../services/board_service.dart';
import '../widgets/navbar.dart';

class NewLabelPage extends StatefulWidget {
  final String boardName;

  const NewLabelPage({super.key, required this.boardName});

  @override
  State<NewLabelPage> createState() => _NewLabelPageState();
}

class _NewLabelPageState extends State<NewLabelPage> {
  final BoardService _boardService = BoardService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final List<SubLabelController> _subLabels = [];

  bool _isLoading = true;
  String? _error;
  Board? _board;

  // Step 2: Components
  bool _showComponentsStep = false;
  List<Component> _availableComponents = [];
  List<ComponentItem> _selectedComponents = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    for (var subLabel in _subLabels) {
      subLabel.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBoard() async {
    try {
      final boards = await _boardService.getBoards();
      final board = boards.firstWhere(
        (b) => b.name == widget.boardName,
        orElse: () => Board(id: '', name: ''),
      );

      if (board.id.isEmpty) {
        setState(() {
          _error = 'Board not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _board = board;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addSubLabel() {
    setState(() {
      _subLabels.add(SubLabelController());
    });
  }

  void _removeSubLabel(int index) {
    setState(() {
      _subLabels[index].controller.dispose();
      _subLabels.removeAt(index);
    });
  }

  Future<void> _loadComponents() async {
    if (_board == null) return;

    try {
      final components = await _boardService.getComponents(_board!.id);
      setState(() {
        _availableComponents = components;
        _availableComponents.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      });
    } catch (e) {
      // Ignore errors, empty list
    }
  }

  Future<void> _confirmLabelStep() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final labelName = _nameController.text.trim();

      // Check if label exists
      final labels = await _boardService.getLabels(_board!.id);
      final labelExists = labels.any(
        (label) => label.name.toLowerCase() == labelName.toLowerCase(),
      );

      if (labelExists) {
        setState(() {
          _errorMessage =
              'A label with name "$labelName" already exists for this board';
          _isLoading = false;
        });
        return;
      }

      // Check duplicate sublabels
      if (_subLabels.isNotEmpty) {
        final subLabelNames = _subLabels
            .map((sl) => sl.controller.text.trim().toLowerCase())
            .toList();
        final uniqueNames = subLabelNames.toSet();

        if (subLabelNames.length != uniqueNames.length) {
          setState(() {
            _errorMessage =
                'Duplicate sublabel names are not allowed within the same label';
            _isLoading = false;
          });
          return;
        }
      }

      // Load components for next step
      await _loadComponents();

      setState(() {
        _showComponentsStep = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _addComponent() {
    setState(() {
      _selectedComponents.add(ComponentItem(id: -1, name: '', pins: []));
    });
  }

  void _removeComponent(int index) {
    setState(() {
      _selectedComponents.removeAt(index);
    });
  }

  Future<void> _loadComponentPins(int componentId, int index) async {
    try {
      final pins = await _boardService.getComponentPins(componentId);
      pins.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _selectedComponents[index].pins = pins;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _finalConfirm() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validation
    for (var comp in _selectedComponents) {
      if (comp.id == -1 || comp.selectedPin == null) {
        setState(() {
          _errorMessage =
              'All components must have a component and pin selected';
          _isLoading = false;
        });
        return;
      }
    }

    // Check duplicates
    final tuples = _selectedComponents.map((comp) {
      return {
        'componentId': comp.id,
        'pinId': comp.selectedPin!.id,
        'sublabel': comp.selectedSublabel,
      };
    }).toList();

    final tupleStrings = tuples
        .map((t) => '${t['componentId']}-${t['pinId']}-${t['sublabel']}')
        .toList();
    final uniqueTuples = tupleStrings.toSet();

    if (tupleStrings.length != uniqueTuples.length) {
      setState(() {
        _errorMessage =
            'Duplicate component-pin-sublabel combinations are not allowed';
        _isLoading = false;
      });
      return;
    }

    // Check mixed None/Sublabel for same pin
    final componentPinPairs = <String, Set<String?>>{};
    for (var tuple in tuples) {
      final key = '${tuple['componentId']}-${tuple['pinId']}';
      final sublabel = tuple['sublabel'] as String?;

      if (!componentPinPairs.containsKey(key)) {
        componentPinPairs[key] = <String?>{};
      }
      componentPinPairs[key]!.add(sublabel);
    }

    for (var entry in componentPinPairs.entries) {
      final sublabels = entry.value;
      if (sublabels.contains(null) && sublabels.length > 1) {
        setState(() {
          _errorMessage =
              'Cannot have the same component-pin with both a sublabel and None';
          _isLoading = false;
        });
        return;
      }
    }

    try {
      // 1. Create Label
      final labelName = _nameController.text.trim();
      final labelDescription = _commentController.text.trim();

      final label = await _boardService.createLabel(
        labelName,
        _board!.id,
        labelDescription.isEmpty ? null : labelDescription,
      );

      // 2. Create Sublabels
      final sublabelMap = <String, int>{};
      for (var subLabel in _subLabels) {
        final subLabelName = subLabel.controller.text.trim();
        final createdSubLabel = await _boardService.createSubLabel(
          subLabelName,
          label.id,
        );
        sublabelMap[subLabelName] = createdSubLabel.id;
      }

      // 3. Create Pad Labels
      for (var comp in _selectedComponents) {
        final componentId = comp.id;
        final pinId = comp.selectedPin!.id;
        final sublabelName = comp.selectedSublabel;

        final padId = await _boardService.getPadId(componentId, pinId);
        final sublabelId = sublabelName != null
            ? sublabelMap[sublabelName]
            : null;

        await _boardService.createPadLabel(padId, label.id, sublabelId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Label created successfully!')),
        );
        context.pop(); // Go back
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const NavBar(), body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading && _board == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                const Icon(Icons.label, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  _showComponentsStep ? 'Add Components' : 'New Label',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Board: ${widget.boardName}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (_showComponentsStep)
            _buildComponentsStep()
          else
            _buildLabelStep(),
        ],
      ),
    );
  }

  Widget _buildLabelStep() {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Label Name',
                  hintText: 'Enter label name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  hintText: 'Enter comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sublabels',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: _addSubLabel,
                    tooltip: 'Add sublabel',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_subLabels.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No sublabels added')),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subLabels.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _subLabels[index].controller,
                              decoration: InputDecoration(
                                labelText: 'Sublabel ${index + 1}',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSubLabel(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmLabelStep,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Next: Components'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentsStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Components',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: _addComponent,
                  tooltip: 'Add component',
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedComponents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No components added')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedComponents.length,
                itemBuilder: (context, index) {
                  return _buildComponentItem(index);
                },
              ),

            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showComponentsStep = false;
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _finalConfirm,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Label'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentItem(int index) {
    final component = _selectedComponents[index];
    final hasComponent = component.id != -1;
    final hasPins = hasComponent && component.pins.isNotEmpty;

    return Card(
      color: Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Component>(
                    decoration: const InputDecoration(
                      labelText: 'Component',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: component.id == -1
                        ? null
                        : _availableComponents.firstWhere(
                            (c) => c.id == component.id,
                            orElse: () => Component(
                              id: component.id,
                              name: component.name,
                            ),
                          ),
                    items: _availableComponents.map((c) {
                      return DropdownMenuItem<Component>(
                        value: c,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (Component? value) async {
                      if (value != null) {
                        setState(() {
                          _selectedComponents[index] = ComponentItem(
                            id: value.id,
                            name: value.name,
                            pins: [],
                            selectedPin: null,
                            selectedSublabel: null,
                          );
                        });
                        await _loadComponentPins(value.id, index);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeComponent(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: hasPins
                      ? DropdownButtonFormField<Pin>(
                          decoration: const InputDecoration(
                            labelText: 'Pin',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          value: component.selectedPin,
                          items: component.pins.map((p) {
                            return DropdownMenuItem<Pin>(
                              value: p,
                              child: Text(p.name),
                            );
                          }).toList(),
                          onChanged: (Pin? value) {
                            if (value != null) {
                              setState(() {
                                _selectedComponents[index].selectedPin = value;
                              });
                            }
                          },
                        )
                      : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Pin',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [],
                          onChanged: null,
                          hint: Text(
                            hasComponent ? 'Loading...' : 'Select component',
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sublabel',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: component.selectedSublabel,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._subLabels.map((sl) {
                        final name = sl.controller.text.trim();
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name.isEmpty ? '(empty)' : name),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _selectedComponents[index].selectedSublabel = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SubLabelController {
  final TextEditingController controller = TextEditingController();
}

class ComponentItem {
  final int id;
  final String name;
  List<Pin> pins;
  Pin? selectedPin;
  String? selectedSublabel;

  ComponentItem({
    required this.id,
    required this.name,
    this.pins = const [],
    this.selectedPin,
    this.selectedSublabel,
  });
}
