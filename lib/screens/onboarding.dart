import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:llam_local/services/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
// Import your HomeScreen
import 'screens.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final SessionManagerService sessionManager = SessionManagerService();
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? userName;

  double _progress = 0.0;
  bool _isDownloaded = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkUserName();
    _checkPermissions();
  }

  void _checkUserName() async {
    String? savedUserName = await sessionManager.getUserName();
    setState(() {
      userName = savedUserName;
    });
    if (savedUserName != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, $savedUserName!')),
      );
    }
  }

  void _setUserName() async {
    if (_formKey.currentState!.validate()) {
      String newUserName = _usernameController.text;
      await sessionManager.saveUserFullName(newUserName);
      setState(() {
        userName = newUserName;
        _currentPage = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name saved successfully!')),
      );
    }
  }

  void _updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  Future<void> _checkPermissions() async {
    bool hasInternet = await _checkInternetConnection();
    bool hasStoragePermission = await _checkStoragePermission();

    if (!hasInternet) {
      _showRequirementsDialog(
          hasInternet: false, hasStoragePermission: true, hasEnoughSpace: true);
      return;
    }

    if (!hasStoragePermission) {
      _showPermissionDialog();
      return;
    }

    bool hasEnoughSpace = await _checkAvailableSpace();
    if (!hasEnoughSpace) {
      _showRequirementsDialog(
          hasInternet: true, hasStoragePermission: true, hasEnoughSpace: false);
      return;
    }

    _checkAndDownloadFile();
  }

  Future<bool> _checkInternetConnection() async {
    return await InternetConnectionChecker().hasConnection;
  }

  Future<bool> _checkStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    PermissionStatus status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<bool> _checkAvailableSpace() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        print('Unable to get external storage directory');
        return false;
      }

      final statFs = await File(directory.path).stat();
      final availableSpace = statFs.size / 1024;
      final requiredSpace = 1.5; // 1.5 GB in bytes

      print('FS space: ${availableSpace} GB');
      print('Available space: ${availableSpace} GB');
      print('Required space: ${requiredSpace / (1024 * 1024 * 1024)} GB');
      print(' space status: ${availableSpace >= requiredSpace} ');
      if (availableSpace >= requiredSpace) {
        print('Enough space available');
        return true;
      } else {
        print('Insufficient space available');
        return false;
      }
      // return availableSpace >= requiredSpace;
    } catch (e) {
      print('Error checking available space: $e');
      return false;
    }
  }

  void _showRequirementsDialog(
      {required bool hasInternet,
      required bool hasStoragePermission,
      required bool hasEnoughSpace}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Requirements not met'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasInternet)
                Text('• No active internet connection detected.'),
              if (!hasStoragePermission)
                Text('• Storage permission not granted.'),
              if (!hasEnoughSpace)
                Text(
                    '• Insufficient storage space. 1.5 GB free space required.'),
              SizedBox(height: 16),
              Text('Please ensure you meet these requirements and try again.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkPermissions();
              },
            ),
            TextButton(
              child: Text('Exit'),
              onPressed: () {
                exit(0);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndDownloadFile() async {
    Directory? externalDir = await getExternalStorageDirectory();
    String savePath = '${externalDir?.path}/tinyllam.gguf';

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
  }

  Future<void> _downloadFile(String savePath) async {
    try {
      await ApiBaseHelper.download(
        'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q8_0.gguf?download=true',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
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
        sessionManager.saveDownloadStatus('downloaded');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text(
              'This app needs storage permission to function properly. Please grant the required permission.'),
          actions: <Widget>[
            TextButton(
              child: Text('Grant Permission'),
              onPressed: () async {
                Navigator.of(context).pop();
                bool hasPermission = await _checkStoragePermission();
                if (hasPermission) {
                  _checkPermissions();
                } else {
                  _showRequirementsDialog(
                      hasInternet: true,
                      hasStoragePermission: false,
                      hasEnoughSpace: true);
                }
              },
            ),
            TextButton(
              child: Text('Exit'),
              onPressed: () {
                exit(0);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TinyChat - Setup',
              style: TextStyle(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: userName == null ? _buildUserNameForm() : _buildContent(),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageIndicator(0),
                  const SizedBox(width: 8),
                  _buildPageIndicator(1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int pageIndex) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == pageIndex ? Colors.blue : Colors.grey,
      ),
    );
  }

  Widget _buildUserNameForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 250.0,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Welcome',
                        textStyle: const TextStyle(
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 300.0,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Please enter your name to continue',
                        textStyle: const TextStyle(
                          fontSize: 18.0,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: _setUserName,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return _isDownloaded
        ? WelcomeMessage(userName: userName!)
        : DownloadProgress(progress: _progress, userName: userName!);
  }
}

class DownloadProgress extends StatelessWidget {
  final double progress;
  final String userName;

  const DownloadProgress(
      {required this.progress, required this.userName, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 250.0,
          child: AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Hello, $userName!',
                textStyle: const TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
            totalRepeatCount: 1,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 300.0,
          child: AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Setup is in progress, please be patient',
                textStyle: const TextStyle(
                  fontSize: 18.0,
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
            totalRepeatCount: 1,
          ),
        ),
        const SizedBox(height: 48),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 20,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${(progress * 100).toStringAsFixed(2)}%',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class WelcomeMessage extends StatelessWidget {
  final String userName;

  const WelcomeMessage({required this.userName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 300.0,
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Setup is complete, $userName!',
                      textStyle: const TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Start', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}
