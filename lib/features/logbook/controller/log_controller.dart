import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:flutter/material.dart';
import '../model/log_model.dart';
import '../../../services/mongo_service.dart';
import '../../../services/access_control_service.dart'; 
import '../../../helpers/log_helper.dart';

class LogController {
  final String userId;
  final String userRole;
  final String teamId;
  
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final MongoService _mongoService;

  LogController({
    required this.userId,
    required this.userRole,
    required this.teamId,
    MongoService? mongoService,
  }) : _mongoService = mongoService ?? MongoService();

  Future<void> syncPendingLogs() async {
    final allLocalLogs = _myBox.values.toList();
    
    for (int i = 0; i < allLocalLogs.length; i++) {
      final log = allLocalLogs[i];
      if (log.id == null) {
        try {
          final cloudLog = await _mongoService.insertLog(log);
          await _myBox.putAt(i, cloudLog);
        } catch (e) {
          print("Gagal setor log index $i: $e");
        }
      }
    }
  }

  Future<void> loadLogs() async {
    logsNotifier.value = _myBox.values.toList();

    try {
      await syncPendingLogs();
      final cloudData = await _mongoService.getLogs(teamId);
      await _myBox.clear();
      await _myBox.addAll(cloudData);

      logsNotifier.value = _myBox.values.toList();
      await LogHelper.writeLog("SYNC COMPLETE: Semua data terverifikasi", level: 2);
    } catch (e) {
      await LogHelper.writeLog("OFFLINE MODE: Gagal sinkronisasi", level: 1);
    }
  }

  Future<void> addLog(String title, String desc, String category, bool isPublic) async {
    final newLog = LogModel(
      id: null, 
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: userId,
      teamId: teamId,
      category: category,
      isPublic: isPublic
    );

    final int hiveIndex = await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];
    try {
    final cloudLog = await _mongoService.insertLog(newLog);
    await _myBox.putAt(hiveIndex, cloudLog);
    logsNotifier.value = _myBox.values.toList(); 
    await LogHelper.writeLog("SUCCESS: Terverifikasi di Atlas", source: "log_controller.dart");
  } catch (e) {
    await LogHelper.writeLog("OFFLINE: Tersimpan di HP saja", level: 1);
  }
}

  Future<void> updateLog(int index, String title, String desc, String category, bool isPublic) async {
    final target = logsNotifier.value[index];
    final bool isOwner = target.authorId == userId;

    if (!AccessControlService.canPerform(userRole, AccessControlService.actionUpdate, isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY BREACH: Unauthorized update attempt", level: 1);
      return; 
    }

    final updatedLog = LogModel(
      id: target.id,
      title: title,
      description: desc,
      date: target.date,
      authorId: target.authorId,
      teamId: target.teamId,
      category: category,
      isPublic: isPublic
    );

    try {
      await _myBox.putAt(index, updatedLog);
      await _mongoService.updateLog(updatedLog);
      await loadLogs(); 
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeLog(int index) async {
    final target = logsNotifier.value[index];
    final bool isOwner = target.authorId == userId;
    if (!AccessControlService.canPerform(userRole, AccessControlService.actionDelete, isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY BREACH: Unauthorized delete attempt", level: 1);
      return;
    }

    try {
      if (target.id != null) {
        await _mongoService.deleteLog(ObjectId.fromHexString(target.id!));
        await _myBox.deleteAt(index);
        await loadLogs();
      }
    } catch (e) {
      rethrow;
    }
  }
}