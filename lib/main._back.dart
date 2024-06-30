import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/services.dart'; // Adjust import for API base client
import 'screens/downloaded_models.dart'; // Import the DownloadedModelScreen

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures all plugins are initialized

  var storagePermission = await Permission.manageExternalStorage.status;
  if (storagePermission.isDenied) {
    await Permission.manageExternalStorage.request();
  }

  runApp(MainApp()); // Removed const keyword
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DownloadManager(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DownloadedModelScreen()));
                  },
                  child: Text('View Downloaded Files'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DownloadManager extends StatefulWidget {
  const DownloadManager({Key? key}) : super(key: key);

  @override
  _DownloadManagerState createState() => _DownloadManagerState();
}

class _DownloadManagerState extends State<DownloadManager> {
  double _progress = 0.0;
  bool _isDownloaded = false;

  void _updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  Future<void> _checkAndDownloadFile() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      // Define download path
      Directory? externalDir = await getExternalStorageDirectory();
      String savePath = '${externalDir?.path}/15MB.mp4';

      File file = File(savePath);
      if (await file.exists()) {
        setState(() {
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File already exists')),
        );
      } else {
        _downloadFile(savePath);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  Future<void> _downloadFile(String savePath) async {
    try {
      await ApiBaseHelper.download(
        '/wp-content/uploads/2023/06/15MB.mp4', // Endpoint for downloading the video file
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Calculate progress percentage
            double progress = received / total;
            _updateProgress(progress);
          }
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded successfully')),
      );
      setState(() {
        _isDownloaded = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndDownloadFile();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _isDownloaded
            ? Text('File is already downloaded.')
            : LinearProgressIndicator(value: _progress),
        Text(
            '${(_progress * 100).toStringAsFixed(2)}%'), // Display progress percentage
      ],
    );
  }
}
