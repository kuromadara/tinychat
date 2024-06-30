import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Unleash the power of AI',
                        'Experience seamless, intelligent conversations with our app that runs TinyLLaMA locally, ensuring privacy, speed, and offline capability.',
                        Icons.rocket_launch,
                      ),
                      SizedBox(height: 24),
                      _buildSection(
                        'About the Developer',
                        'Dayananda Dowarah is a passionate Fullstack Developer with expertise in web and mobile technologies, specializing in PHP, Laravel, and Flutter.',
                        Icons.person,
                      ),
                      SizedBox(height: 24),
                      _buildSocialLinks(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.lightBlue],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                width: 100,
                height: 100,
              ),
              SizedBox(height: 16),
              Text(
                'TinyChat',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'AI-powered conversations',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect with me:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSocialButton(
                Icons.code, 'GitHub', 'https://github.com/kuromadara'),
            _buildSocialButton(Icons.question_answer, 'Stack Overflow',
                'https://stackoverflow.com/users/14418303/kuro'),
            _buildSocialButton(
                Icons.work, 'LinkedIn', 'https://www.linkedin.com/in/dayd/'),
            _buildSocialButton(Icons.flutter_dash, 'Pub.dev',
                'https://pub.dev/publishers/dayananda.tech/packages'),
            _buildSocialButton(Icons.web, 'Portfolio',
                'https://portfolio-kuromadara.vercel.app/'),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label, String url) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _launchURL(url),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await url_launcher.canLaunchUrl(url)) {
        await url_launcher.launchUrl(url,
            mode: url_launcher.LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('Error launching URL: $e');
      // You might want to show a snackbar or dialog here to inform the user
    }
  }
}
