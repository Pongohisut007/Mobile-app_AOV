import 'dart:io';

import 'package:flutter_application_1/models/recipe_step.dart';

enum RecipeMediaKind { image, video }

class PendingRecipeUpload {
  const PendingRecipeUpload({
    required this.file,
    required this.name,
    required this.kind,
    required this.mimeType,
  });

  final File file;
  final String name;
  final RecipeMediaKind kind;
  final String mimeType;
}

class RecipeContentDraft {
  const RecipeContentDraft({
    required this.title,
    required this.textContent,
    required this.contentType,
    required this.durationMinutes,
    this.media,
    this.existingMediaUrl,
  });

  final String title;
  final String textContent;
  final String contentType;
  final int? durationMinutes;
  final PendingRecipeUpload? media;

  // URL ของไฟล์ที่อัปโหลดไว้แล้ว (ตอนแก้ไขสูตร) ใช้ต่อเมื่อไม่ได้เลือกไฟล์ใหม่
  final String? existingMediaUrl;

  bool get hasMedia => media != null || existingMediaUrl != null;
}

class RecipeSectionGroupDraft {
  const RecipeSectionGroupDraft({required this.title, required this.contents});

  final String title;
  final List<RecipeContentDraft> contents;
}

class RecipeSectionDraft {
  const RecipeSectionDraft({required this.sections});

  /// แปลงขั้นตอนของสูตรที่โหลดจาก backend กลับเป็น draft สำหรับหน้าแก้ไข
  factory RecipeSectionDraft.fromSteps(List<RecipeStep> steps) {
    final sections = <RecipeSectionGroupDraft>[];
    String? currentSectionKey;
    for (final step in steps) {
      final sectionKey = step.sectionId.isEmpty
          ? step.sectionTitle
          : step.sectionId;
      if (sectionKey != currentSectionKey) {
        currentSectionKey = sectionKey;
        sections.add(
          RecipeSectionGroupDraft(title: step.sectionTitle, contents: []),
        );
      }
      final mediaUrl = step.mediaUrl?.trim();
      final duration = step.durationSeconds;
      sections.last.contents.add(
        RecipeContentDraft(
          title: step.title,
          textContent: step.description,
          contentType: step.contentType,
          durationMinutes: duration == null ? null : (duration / 60).round(),
          existingMediaUrl: mediaUrl == null || mediaUrl.isEmpty
              ? null
              : mediaUrl,
        ),
      );
    }
    return RecipeSectionDraft(sections: sections);
  }

  final List<RecipeSectionGroupDraft> sections;
}
