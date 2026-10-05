import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// cache ของผลลัพธ์จาก API (เก็บเป็นข้อความ JSON ดิบ) ใช้แสดงทันทีแล้วค่อยโหลดของใหม่มาแทน
///
/// - RAM: อ่านได้ทันที (sync) ตอนสร้างหน้า
/// - disk: ปิดแอปแล้วเปิดใหม่ หน้าแรก/สูตรที่เคยเปิด/โปรไฟล์ ขึ้นได้เลยไม่ต้องรอเน็ต
///
/// key ที่ขึ้นต้นด้วย [userPrefix] เป็นข้อมูลของคนที่ login อยู่ (โปรไฟล์, สูตรที่ซื้อแล้ว)
/// ถูกล้างด้วย [clearUser] ตอนเปลี่ยนบัญชี ที่เหลือเป็นข้อมูลสาธารณะใช้ร่วมกันได้
class ApiCache {
  ApiCache({
    Future<Directory?> Function()? directory,
    this.maxDiskEntries = 300,
  }) : _directoryLoader = directory ?? _defaultDirectory;

  static ApiCache instance = ApiCache();

  static const userPrefix = 'user:';

  /// เก็บบน disk ได้มากสุดกี่รายการ (เกินแล้วลบอันที่เก่าสุดทิ้ง)
  final int maxDiskEntries;

  /// ใน RAM เก็บไม่เกินเท่านี้ (ใช้ล่าสุดอยู่ท้าย)
  static const _maxMemoryEntries = 200;

  final Future<Directory?> Function() _directoryLoader;
  final _memory = <String, String>{};
  Future<Directory?>? _directory;
  int _writesSincePrune = 0;

  /// อ่านจาก RAM อย่างเดียว (ใช้ตอน build/initState ที่ต้องได้ค่าทันที)
  String? peek(String key) {
    final value = _memory.remove(key);
    if (value != null) _memory[key] = value;
    return value;
  }

  /// RAM ก่อน ไม่มีค่อยอ่านจาก disk (อ่านไม่ได้ = null ไม่ throw)
  Future<String?> read(String key) async {
    final inMemory = peek(key);
    if (inMemory != null) return inMemory;
    try {
      final file = await _file(key);
      if (file == null || !await file.exists()) return null;
      final value = await file.readAsString();
      _remember(key, value);
      return value;
    } on Object {
      return null;
    }
  }

  /// ไม่ต้อง await ก็ได้: เขียน disk ไม่ทันหรือพลาด แค่ครั้งหน้าไม่มี cache
  Future<void> write(String key, String value) async {
    _remember(key, value);
    try {
      final file = await _file(key);
      if (file == null) return;
      await file.writeAsString(value, flush: false);
      if (++_writesSincePrune >= 20) {
        _writesSincePrune = 0;
        await _prune();
      }
    } on Object {
      // disk เต็ม/ไม่มีสิทธิ์ ใช้ RAM อย่างเดียวไป
    }
  }

  Future<void> remove(String key) async {
    _memory.remove(key);
    try {
      final file = await _file(key);
      if (file != null && await file.exists()) await file.delete();
    } on Object {
      // ไม่มีไฟล์ก็ไม่เป็นไร
    }
  }

  /// เปลี่ยนบัญชี: ทิ้งข้อมูลของคนเก่า (ข้อมูลสาธารณะยังใช้ต่อได้)
  Future<void> clearUser() => _clearWhere((key) => key.startsWith(userPrefix));

  /// ล้างทั้งหมด
  Future<void> clear() => _clearWhere((_) => true);

  Future<void> _clearWhere(bool Function(String key) test) async {
    _memory.removeWhere((key, _) => test(key));
    try {
      final directory = await _dir();
      if (directory == null || !await directory.exists()) return;
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final key = _keyOf(entity);
        if (key != null && test(key)) await entity.delete();
      }
    } on Object {
      // ลบไม่ได้ครั้งนี้ ไม่เป็นไร
    }
  }

  void _remember(String key, String value) {
    _memory.remove(key);
    _memory[key] = value;
    while (_memory.length > _maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  Future<void> _prune() async {
    final directory = await _dir();
    if (directory == null) return;
    final files = await directory.list().where((e) => e is File).toList();
    if (files.length <= maxDiskEntries) return;
    final stats = await Future.wait(
      files.map((file) async => (file, (await file.stat()).modified)),
    );
    stats.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (file, _) in stats.take(files.length - maxDiskEntries)) {
      await file.delete();
    }
  }

  Future<Directory?> _dir() => _directory ??= _directoryLoader();

  Future<File?> _file(String key) async {
    final directory = await _dir();
    if (directory == null) return null;
    // ชื่อไฟล์ = key แบบ base64url (กลับเป็น key ได้ตอนล้างข้อมูลของผู้ใช้)
    final name = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${directory.path}${Platform.pathSeparator}$name.json');
  }

  static String? _keyOf(File file) {
    final name = file.uri.pathSegments.last;
    if (!name.endsWith('.json')) return null;
    var encoded = name.substring(0, name.length - 5);
    encoded += '=' * ((4 - encoded.length % 4) % 4);
    try {
      return utf8.decode(base64Url.decode(encoded));
    } on FormatException {
      return null;
    }
  }

  static Future<Directory?> _defaultDirectory() async {
    try {
      final base = await getApplicationSupportDirectory();
      final directory = Directory(
        '${base.path}${Platform.pathSeparator}api_cache',
      );
      await directory.create(recursive: true);
      return directory;
    } on MissingPluginException {
      // เทสต์/แพลตฟอร์มที่ไม่มี path_provider: ใช้ RAM อย่างเดียว
      return null;
    } on Object catch (error) {
      debugPrint('API cache disabled: $error');
      return null;
    }
  }
}
