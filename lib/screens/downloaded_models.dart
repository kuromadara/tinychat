import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llam_local/services/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class DownloadedModelScreen extends StatefulWidget {
  const DownloadedModelScreen({Key? key}) : super(key: key);

  @override
  State<DownloadedModelScreen> createState() => _DownloadedModelScreenState();
}

class _DownloadedModelScreenState extends State<DownloadedModelScreen> {
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;
  SessionManagerService sessionManager = SessionManagerService();

  @override
  void initState() {
    super.initState();
    _listDownloadedFiles();
  }

  Future<void> _listDownloadedFiles() async {
    setState(() => _isLoading = true);
    if (await Permission.manageExternalStorage.request().isGranted) {
      Directory? externalDir = await getExternalStorageDirectory();
      String dirPath = '${externalDir?.path}';
      Directory dir = Directory(dirPath);
      if (await dir.exists()) {
        setState(() {
          _downloadedFiles = dir.listSync()
            ..sort((a, b) =>
                b.statSync().modified.compareTo(a.statSync().modified));
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      setState(() {
        _downloadedFiles.remove(file);
        sessionManager.deleteDownloadStatus();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('File deleted successfully. The app will now exit.')),
      );
      // Wait for 2 seconds to show the snackbar before exiting
      await Future.delayed(const Duration(seconds: 2));
      _forceStopApp();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  void _forceStopApp() {
    SystemNavigator.pop(); // This will close the app on Android
    exit(0); // This will force close the app on both Android and iOS
  }

  String _getFileSize(File file) {
    int sizeInBytes = file.lengthSync();
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024)
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    if (sizeInBytes < 1024 * 1024 * 1024)
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _listDownloadedFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No models downloaded',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _listDownloadedFiles,
                  child: ListView.builder(
                    itemCount: _downloadedFiles.length,
                    itemBuilder: (context, index) {
                      FileSystemEntity entity = _downloadedFiles[index];
                      if (entity is File) {
                        String fileName = entity.path.split('/').last;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Icon(Icons.file_present,
                                color: Theme.of(context).primaryColor),
                            title: Text(fileName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Size: ${_getFileSize(entity)}'),
                                Text(
                                    'Modified: ${DateFormat.yMd().add_jm().format(entity.statSync().modified)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(entity),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
    );
  }

  Future<void> _showDeleteConfirmation(FileSystemEntity file) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to delete "${file.path.split('/').last}"?'),
                const Text('This action cannot be undone.'),
                const SizedBox(height: 10),
                const Text('The app will exit after deleting the file.',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFile(file);
              },
            ),
          ],
        );
      },
    );
  }
}
