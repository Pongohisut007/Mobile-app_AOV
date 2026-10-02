import 'dart:io';

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
  });

  final String title;
  final String textContent;
  final String contentType;
  final int? durationMinutes;
  final PendingRecipeUpload? media;
}

class RecipeSectionDraft {
  const RecipeSectionDraft({required this.title, required this.contents});

  final String title;
  final List<RecipeContentDraft> contents;
}
