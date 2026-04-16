import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/logbook/controller/log_controller.dart';
import 'package:logbook_app_001/features/logbook/model/log_model.dart';
import 'module4_savetocloud_test.mocks.dart';

@GenerateMocks([MongoService])
void main() {
  late LogController controller;
  late MockMongoService mockMongo;

  // Helper untuk membuat dummy LogModel agar kode test tidak panjang
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

  group('Module 4 - Save To Cloud (Fixed)', () {
    test('Data di Hive harus terupdate dengan ID dari Atlas setelah berhasil simpan', () async {
      final cloudResponse = createDummyLog(id: "mongo_id_123", title: "Testing Cloud");
      when(mockMongo.insertLog(any)).thenAnswer((_) async => cloudResponse);
      await controller.addLog("Testing Cloud", "Deskripsi Logbook", "Kategori Logbook", true);
      final savedLog = Hive.box<LogModel>('offline_logs').getAt(0);
      expect(savedLog?.id, "mongo_id_123");
    });

    test('loadLogs harus mengganti data lokal dengan data terbaru dari Atlas', () async {
      final log1 = createDummyLog(id: "id_1");
      final log2 = createDummyLog(id: "id_2");
      final cloudData = [log1, log2]; 
      when(mockMongo.getLogs(any)).thenAnswer((_) async => cloudData);
      await controller.loadLogs();
      expect(controller.logsNotifier.value.length, 2);
      expect(Hive.box<LogModel>('offline_logs').length, 2);
    });

    test('updateLog harus mengirim data yang diperbarui ke Atlas', () async {
      final initialLog = createDummyLog(id: "old_id");
      await Hive.box<LogModel>('offline_logs').add(initialLog);
      await controller.loadLogs();
      when(mockMongo.updateLog(any)).thenAnswer((_) async => {});
      await controller.updateLog(0, "Judul Baru", "Desc Baru", "Cat", false);
      verify(mockMongo.updateLog(argThat(predicate((LogModel log) => log.title == "Judul Baru")))).called(1);
    });
  });
}