import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// รูปที่พร้อมอัปโหลด (ย่อแล้ว หรือไฟล์เดิมถ้าย่อไม่ได้/ไม่คุ้ม)
class UploadImage {
  const UploadImage({
    required this.file,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final File file;
  final String name;
  final String mimeType;
  final int size;
}

/// ย่อรูปก่อนอัปโหลด: ด้านสั้นเหลือราว 1280px, JPEG quality 85
/// รูปจากกล้องมือถือ 3-5 MB จะเหลือราว 200-400 KB โหลดเร็วขึ้นทุกที่ที่แสดงรูปนี้
/// GIF ไม่ย่อ (จะเสียภาพเคลื่อนไหว) และถ้าย่อแล้วไม่เล็กลงก็ใช้ไฟล์เดิม
Future<UploadImage> prepareImageForUpload({
  required File file,
  required String name,
  required String mimeType,
}) async {
  final original = UploadImage(
    file: file,
    name: name,
    mimeType: mimeType,
    size: await file.length(),
  );
  if (mimeType == 'image/gif') return original;

  try {
    final baseName = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    final targetPath =
        '${Directory.systemTemp.path}/upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 1280,
      minHeight: 1280,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) return original;

    final compressedFile = File(compressed.path);
    final compressedSize = await compressedFile.length();
    if (compressedSize >= original.size) return original;

    return UploadImage(
      file: compressedFile,
      name: '$baseName.jpg',
      mimeType: 'image/jpeg',
      size: compressedSize,
    );
  } catch (error) {
    // ย่อไม่ได้ (เช่นไฟล์แปลก ๆ) ก็อัปโหลดไฟล์เดิมไป ไม่ให้ผู้ใช้ติด
    debugPrint('Image compression skipped: $error');
    return original;
  }
}
