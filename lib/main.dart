import 'package:flutter/material.dart';
import 'services/services.dart';
import 'routes/routes.dart';
import 'ui/ui.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiBaseHelper.setupDio();
  SessionManagerService sessionManager = SessionManagerService();

  String? userName = await sessionManager.getUserName();
  String? downloadStatus = await sessionManager.getDownloadStatus();

  String initialRoute = "";

  if (userName != null && downloadStatus == "downloaded") {
    initialRoute = AppRoutes.home;
  } else {
    initialRoute = AppRoutes.onBoarding;
  }

  runApp(MainApp(initialRoute: initialRoute));
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electro',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
      onGenerateRoute: (settings) {
        return FadePageRoute(page: AppRoutes.routes[settings.name]!(context));
      },
    );
  }
}
