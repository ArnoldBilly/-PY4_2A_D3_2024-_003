import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app_001/features/logbook/controller/log_controller.dart';
import 'package:logbook_app_001/features/logbook/model/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'module3_savetodisk_test.mocks.dart';

@GenerateMocks([MongoService])
void main() {
  late LogController controller;
  late MockMongoService mockMongo;

  LogModel createDummyLog({String? id, String title = "Test"}) {
    return LogModel(
      id: id,
      title: title,
      description: "Desc",
      date: DateTime.now().toString(),
      authorId: "user_001",
      teamId: "tim_1",
      category: "Pribadi",
      isPublic: true,
    );
  }
  
  setUp(() async {
    await dotenv.load(fileName: ".env");
    await setUpTestHive(); 
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogModelAdapter());
    }
    await Hive.openBox<LogModel>('offline_logs');

    mockMongo = MockMongoService();
    controller = LogController(
      userId: "user_001",
      userRole: "Ketua",
      teamId: "tim_1",
      mongoService: mockMongo,
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('Module 3 - Save To Disk (3 Test)', () {
    test('Harus tetap menyimpan ke Hive jika MongoDB offline', () async {
      when(mockMongo.insertLog(any)).thenThrow(Exception("No Internet"));
      await controller.addLog("Offline Log", "Isi Log", "Pribadi", false);

      final box = Hive.box<LogModel>('offline_logs');
      expect(box.length, 1);
      expect(box.getAt(0)?.title, "Offline Log");
      expect(box.getAt(0)?.id, isNull);
    });

    test('ValueNotifier harus terupdate segera setelah simpan ke disk', () async {
      await controller.addLog("Update UI", "Cek Notifier", "UI", true);
      final currentLogs = controller.logsNotifier.value;
      expect(currentLogs.length, 1);
      expect(currentLogs.first.title, "Update UI");
    });

    test('Harus mendeteksi dan mencoba kirim data yang id-nya null di disk', () async {
      final pendingLog = LogModel(title: "Pending", description: "...", date: "...", authorId: "user1", teamId: "tim1", category: "Pribadi", isPublic: false);
      await Hive.box<LogModel>('offline_logs').add(pendingLog);
      when(mockMongo.insertLog(any)).thenAnswer((_) async => 
        createDummyLog(id: "new_id_dari_atlas", title: "Pending")
      );
      await controller.syncPendingLogs();
      verify(mockMongo.insertLog(any)).called(1);
    });
  });
}