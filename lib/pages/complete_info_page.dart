import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../services/file_upload_service.dart';
import '../router/app_router.dart';

/// Complete Information Page
///
/// This page allows users to upload a CVG file to create a board
/// with complete information (IPC flow).
///
/// Requirements: 4.4
class CompleteInfoPage extends StatefulWidget {
  const CompleteInfoPage({super.key});

  @override
  State<CompleteInfoPage> createState() => _CompleteInfoPageState();
}

class _CompleteInfoPageState extends State<CompleteInfoPage> {
  bool _isUploading = false;
  String _uploadMessage = '';
  double _uploadProgress = 0.0;
  String? _selectedFileName;
  String? _currentTaskId;
  bool _isCancelled = false;

  Future<void> _pickAndUploadCvgFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['cvg'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _isUploading = true;
        _uploadMessage = 'Starting CVG upload...';
        _uploadProgress = 0.0;
        _uploadMessage = 'Starting CVG upload...';
        _uploadProgress = 0.0;
        _currentTaskId = null;
        _isCancelled = false;
      });

      try {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        final response = await FileUploadService.uploadCvgAsync(
          bytes,
          fileName,
          onTaskIdReceived: (taskId) {
            _currentTaskId = taskId;
          },
          isCancelled: () => _isCancelled,
          progressCallback: (message, progress) {
            // Check if widget is still mounted
            if (!mounted) {
              return;
            }

            setState(() {
              _uploadMessage = message;
              _uploadProgress = progress.toDouble();
            });
          },
        );

        if (response['status'] == 'completed') {
          final boardId = response['board_id'].toString();

          if (mounted) {
            setState(() {
              _uploadMessage = 'CVG Upload Complete';
              _uploadProgress = 100;
            });
          }

          await Future.delayed(const Duration(milliseconds: 500));

          // Get board details to retrieve the board name
          final boardDetails = await FileUploadService.getBoardDetails(boardId);
          final boardName = boardDetails['name'] ?? 'Board_$boardId';

          // Navigate to board management page with the new board
          if (mounted) {
            context.go(AppRoutes.buildBoardDetailRoute(boardName));
          }
        } else {
          throw Exception("Upload failed or board creation incomplete.");
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadMessage = 'CVG Upload Failed: $e';
            _uploadProgress = 0;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('CVG upload failed: $e')));
        }
      }
    }
  }

  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop) {
      return;
    }

    if (_isUploading && _currentTaskId != null) {
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Upload?'),
          content: const Text(
            'An upload is currently in progress. Do you want to cancel it and go back?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldCancel == true) {
        try {
          await FileUploadService.cancelUpload(_currentTaskId!);
          if (mounted) {
            setState(() {
              _isUploading = false;
              _uploadMessage = 'Upload cancelled';
              _isCancelled = true;
            });
            context.pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to cancel upload: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      onPopInvoked: _handlePopInvoked,
      child: Scaffold(
        appBar: const NavBar(),
        backgroundColor: const Color(0xFF052234),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 40),

              // Title
              const Text(
                'Complete Information Flow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Full features available with official PCB manufacturing files',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),

              // CVG file button with image
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _pickAndUploadCvgFile,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60),
                      ),
                    ),
                    child: Ink.image(
                      image: const AssetImage('assets/button/ipc_flow_button.png'),
                      fit: BoxFit.cover,
                      width: 300,
                      height: 300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Button label
              const Text(
                'Select CVG File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              // Selected file name
              if (_selectedFileName != null && !_isUploading) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected: $_selectedFileName',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],

              // Progress indicator
              if (_isUploading) ...[
                const SizedBox(height: 40),
                _buildProgressDisplay(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDisplay() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_uploadProgress < 100)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              if (_uploadProgress >= 100)
                const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Processing CVG File',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${_uploadProgress.round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress / 100.0,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            _uploadMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
