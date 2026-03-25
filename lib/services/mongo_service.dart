import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/logbook/model/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  Db? _db;
  DbCollection? _collection;
  static late DbCollection logCollection;

  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }
  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) throw Exception("MONGODB_URI tidak ditemukan di .env");

      _db = await Db.create(dbUri);
      await _db!.open().timeout(const Duration(seconds: 15));
      _collection = _db!.collection('logs');

      await LogHelper.writeLog("DATABASE: Terhubung & Koleksi Siap", source: _source, level: 2);
    } catch (e) {
      await LogHelper.writeLog("DATABASE: Gagal Koneksi - $e", source: _source, level: 1);
      rethrow;
    }
  }

  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );
      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId)) 
          .toList();

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog("ERROR: Fetch Failed - $e", source: _source, level: 1);
      return [];
    }
  }

  Future<LogModel> insertLog(LogModel log) async {
  try {
    final collection = await _getSafeCollection();
    final Map<String, dynamic> mapData = log.toMap();
    mapData.remove('_id'); 

    final result = await collection.insertOne(mapData);
    if (result.isSuccess) {
      await LogHelper.writeLog("SUCCESS: Data tersinkron ke Cloud", source: _source, level: 2);
      return LogModel.fromMap({
        ...mapData,
        '_id': result.id,
      });
    } else {
      throw Exception("WriteResult Gagal");
    }
  } catch (e) {
    await LogHelper.writeLog("ERROR: Insert Failed - $e", source: _source, level: 1);
    rethrow;
  }
}

  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      if (log.id == null) throw Exception("ID Log tidak ditemukan untuk update");

      final objectId = ObjectId.fromHexString(log.id!);

      await collection.replaceOne(
        where.id(objectId), 
        log.toMap(),
        upsert: true, 
      );

      await LogHelper.writeLog("DATABASE: Update '${log.title}' Berhasil", source: _source, level: 2);
    } catch (e) {
      await LogHelper.writeLog("DATABASE: Update Gagal - $e", source: _source, level: 1);
      rethrow;
    }
  }

  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));

      await LogHelper.writeLog("DATABASE: Hapus ID $id Berhasil", source: _source, level: 2);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}
