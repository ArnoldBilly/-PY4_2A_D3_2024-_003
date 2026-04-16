import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/model/log_model.dart';
import 'package:logbook_app_001/features/onboarding/view/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>(
    'offline_logs',
  );
  try {
    // Ambil daftar kamera yang tersedia di perangkat
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Logbook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)
      ),
      home: const OnBoardingView(),
    );
  }
}