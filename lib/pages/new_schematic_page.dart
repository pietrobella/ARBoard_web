import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:image/image.dart' as img;
import '../models/board.dart';
import '../services/board_service.dart';
import '../widgets/navbar.dart';

class NewSchematicPage extends StatefulWidget {
  final String boardName;

  const NewSchematicPage({super.key, required this.boardName});

  @override
  State<NewSchematicPage> createState() => _NewSchematicPageState();
}

class _NewSchematicPageState extends State<NewSchematicPage> {
  final BoardService _boardService = BoardService();
  Board? _board;
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;

  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  PdfController? _pdfController;
  int _currentPage = 1;

  // Cropping state
  Offset? _startPoint;
  Offset? _endPoint;
  final GlobalKey _pdfKey = GlobalKey();

  // List of cropped images to be uploaded
  final List<Map<String, dynamic>> _croppedImages = [];

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadBoard() async {
    try {
      final boards = await _boardService.getBoards();
      final board = boards.firstWhere(
        (b) => b.name == widget.boardName,
        orElse: () => throw Exception('Board not found'),
      );

      if (mounted) {
        setState(() {
          _board = board;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        _fileBytes = file.bytes;

        // Create a copy for the controller
        final bytesForController = Uint8List.fromList(_fileBytes!);
        final document = PdfDocument.openData(bytesForController);

        setState(() {
          _selectedFile = file;
          _pdfController = PdfController(document: document);
          _startPoint = null;
          _endPoint = null;
          _croppedImages.clear();
          _currentPage = 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_selectedFile == null) return;
    final RenderBox renderBox =
        _pdfKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _startPoint = localPosition;
      _endPoint = localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_startPoint == null) return;
    final RenderBox renderBox =
        _pdfKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _endPoint = localPosition;
    });
  }

  Rect? _getSelectionRect() {
    if (_startPoint == null || _endPoint == null) return null;
    return Rect.fromPoints(_startPoint!, _endPoint!);
  }

  Future<void> _addCrop() async {
    if (_fileBytes == null || _startPoint == null || _endPoint == null) return;

    try {
      // Create a NEW copy for this operation to avoid detached buffer issues
      final bytesForOperation = Uint8List.fromList(_fileBytes!);
      final document = await PdfDocument.openData(bytesForOperation);
      final page = await document.getPage(_currentPage);

      final RenderBox renderBox =
          _pdfKey.currentContext!.findRenderObject() as RenderBox;
      final widgetSize = renderBox.size;

      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      await page.close();

      if (pageImage == null) throw Exception('Failed to render PDF page');

      final image = img.decodeImage(pageImage.bytes);
      if (image == null) throw Exception('Failed to decode rendered image');

      final scaleX = image.width / widgetSize.width;
      final scaleY = image.height / widgetSize.height;

      final selection = _getSelectionRect()!;

      final cropX = (selection.left * scaleX).toInt();
      final cropY = (selection.top * scaleY).toInt();
      final cropW = (selection.width * scaleX).toInt();
      final cropH = (selection.height * scaleY).toInt();

      final safeX = cropX.clamp(0, image.width - 1);
      final safeY = cropY.clamp(0, image.height - 1);
      final safeW = cropW.clamp(1, image.width - safeX);
      final safeH = cropH.clamp(1, image.height - safeY);

      final croppedImage = img.copyCrop(
        image,
        x: safeX,
        y: safeY,
        width: safeW,
        height: safeH,
      );

      final pngBytes = img.encodePng(croppedImage);

      setState(() {
        _croppedImages.add({
          'bytes': pngBytes,
          'width': safeW,
          'height': safeH,
          'page': _currentPage,
        });
        _startPoint = null;
        _endPoint = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cropping: $e')));
    }
  }

  Future<void> _uploadAll() async {
    if (_board == null || _croppedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      for (var i = 0; i < _croppedImages.length; i++) {
        final crop = _croppedImages[i];
        await _boardService.uploadCropSchematic(
          _board!.id,
          crop['bytes'] as Uint8List,
          'schematic_${DateTime.now().millisecondsSinceEpoch}_$i.png',
          crop['width'] as int,
          crop['height'] as int,
          function: 'ELECTRICAL',
          side: '',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_croppedImages.length} schematics uploaded successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeCrop(int index) {
    setState(() {
      _croppedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const NavBar(), body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }

    if (_board == null) {
      return const Center(child: Text('Board not found'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const SizedBox(width: 8),
              Text(
                'New Schematic for ${_board!.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Controls
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_open),
                label: Text(
                  _selectedFile == null ? 'Select PDF' : 'Change PDF',
                ),
              ),
              const SizedBox(width: 16),
              if (_selectedFile != null) ...[
                Expanded(
                  child: Text(
                    'File: ${_selectedFile!.name} (Page $_currentPage)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          _pdfController?.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    _pdfController?.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Main Content Area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF View and Cropper
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.grey[200],
                    ),
                    child: _selectedFile == null
                        ? const Center(child: Text('No PDF selected'))
                        : Stack(
                            key: _pdfKey,
                            children: [
                              PdfView(
                                controller: _pdfController!,
                                onPageChanged: (page) {
                                  setState(() {
                                    _currentPage = page;
                                    _startPoint = null;
                                    _endPoint = null;
                                  });
                                },
                                scrollDirection: Axis.vertical,
                                builders:
                                    PdfViewBuilders<DefaultBuilderOptions>(
                                      options: const DefaultBuilderOptions(),
                                      documentLoaderBuilder: (_) =>
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      pageLoaderBuilder: (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                              ),
                              // Gesture Capture Layer (Top)
                              Positioned.fill(
                                child: GestureDetector(
                                  onPanStart: _onPanStart,
                                  onPanUpdate: _onPanUpdate,
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                              // Selection Rectangle (Visual)
                              if (_getSelectionRect() != null)
                                Positioned.fromRect(
                                  rect: _getSelectionRect()!,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                      color: Colors.red.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 24),

                // Sidebar for Cropped Images Preview
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cropped Schematics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('${_croppedImages.length} items'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select an area on the PDF and click "Add Crop" to add to this list.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // List of crops
                          Expanded(
                            child: _croppedImages.isEmpty
                                ? const Center(
                                    child: Text('No crops added yet'),
                                  )
                                : ListView.builder(
                                    itemCount: _croppedImages.length,
                                    itemBuilder: (context, index) {
                                      final crop = _croppedImages[index];
                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ListTile(
                                          leading: Image.memory(
                                            crop['bytes'] as Uint8List,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                          title: Text('Crop ${index + 1}'),
                                          subtitle: Text(
                                            'Page ${crop['page']} - ${crop['width']}x${crop['height']}',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _removeCrop(index),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      (_selectedFile == null ||
                                          _getSelectionRect() == null)
                                      ? null
                                      : _addCrop,
                                  icon: const Icon(Icons.crop),
                                  label: const Text('Add Crop'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  (_croppedImages.isEmpty || _isUploading)
                                  ? null
                                  : _uploadAll,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload),
                              label: Text(
                                'Confirm & Upload (${_croppedImages.length})',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
