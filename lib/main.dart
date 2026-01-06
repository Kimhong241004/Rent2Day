import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'data/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  await storageService.init();
  runApp(RentManagerApp(storageService: storageService));
}

class RentManagerApp extends StatelessWidget {
  final StorageService storageService;
  const RentManagerApp({Key? key, required this.storageService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent Manager',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
      ),
      home: HomeScreen(storageService: storageService),
      debugShowCheckedModeBanner: false,
    );
  }
}
