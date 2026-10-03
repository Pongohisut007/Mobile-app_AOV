import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/repositories/upload_repository.dart';
import 'package:flutter_application_1/views/pages/create_cooking_steps_page.dart';

import 'package:flutter_application_1/widgets/create_food/recipe_basic_info_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_cover_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_detail_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_category_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_steps_section.dart';

class CreateFoodcardPage extends StatefulWidget {
  const CreateFoodcardPage({
    super.key,
    required this.categories,
    this.isFromCommunity = false,
  });

  final List<Category> categories;
  final bool isFromCommunity;

  @override
  State<CreateFoodcardPage> createState() => _CreateFoodcardPageState();
}

class _CreateFoodcardPageState extends State<CreateFoodcardPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _preparationController = TextEditingController();
  final _cookingController = TextEditingController();
  final _servingsController = TextEditingController();
  final _selectedCategoryIds = <String>{};
  final _uploadRepository = HttpUploadRepository(baseUrl: ApiConfig.apiBaseUrl);

  String? _difficulty;
  RecipeSectionDraft? _sectionDraft;
  _PendingUpload? _coverSelection;
  bool _showImgCommu = false;
  bool _isPickingFile = false;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _canPop = false;
  bool _handlingExit = false;

  bool get _isBusy => _isPickingFile || _isUploading;

  bool get _hasDraftContent {
    final sectionDraft = _sectionDraft;
    return _titleController.text.trim().isNotEmpty ||
        _slugController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _coverSelection != null ||
        _preparationController.text.trim().isNotEmpty ||
        _cookingController.text.trim().isNotEmpty ||
        _servingsController.text.trim().isNotEmpty ||
        _difficulty != null ||
        _selectedCategoryIds.isNotEmpty ||
        _showImgCommu ||
        (sectionDraft?.sections.any(
              (section) =>
                  section.title.trim().isNotEmpty ||
                  section.contents.any(
                    (step) =>
                        step.title.trim().isNotEmpty ||
                        step.textContent.trim().isNotEmpty ||
                        step.durationMinutes != null ||
                        step.media != null,
                  ),
            ) ??
            false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationController.dispose();
    _cookingController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (_isBusy || _isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_coverSelection == null) {
      _showMessage('เลือกรูปตัวอย่างอาหารก่อนเผยแพร่สูตร');
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showMessage('เลือกหมวดหมู่อย่างน้อย 1 หมวด');
      return;
    }
    final sectionDraft = _sectionDraft;
    if (sectionDraft == null ||
        sectionDraft.sections.isEmpty ||
        sectionDraft.sections.any((section) => section.contents.isEmpty)) {
      _showMessage('เพิ่มขั้นตอนการทำอาหารก่อนเผยแพร่สูตร');
      return;
    }
    if (sectionDraft.sections.any(
      (section) =>
          section.title.trim().isEmpty ||
          section.contents.any(
            (step) =>
                step.title.trim().isEmpty || step.textContent.trim().isEmpty,
          ),
    )) {
      _showMessage('กรอกชื่อและรายละเอียดให้ครบทุกขั้นตอน');
      return;
    }
    if (!await _persistRecipe(asDraft: false) || !mounted) return;
    _popPage(true);
  }

  Future<bool> _persistRecipe({required bool asDraft}) async {
    if (_isBusy || _isSaving) return false;
    setState(() => _isSaving = true);
    try {
      final creatorId = await TokenStorage().readUserId();
      if (!mounted) return false;
      if (creatorId == null || creatorId.trim().isEmpty) {
        throw Exception('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }

      final sectionDraft = _sectionDraft;
      final sections =
          sectionDraft?.sections ?? const <RecipeSectionGroupDraft>[];
      final steps = sections.expand((section) => section.contents).toList();
      final hasFilesToUpload =
          _coverSelection != null || steps.any((step) => step.media != null);
      UploadedFile? coverUpload;
      final stepUploads = <UploadedFile?>[];
      if (hasFilesToUpload) {
        setState(() => _isUploading = true);
        if (_coverSelection case final selection?) {
          coverUpload = await _uploadPendingFile(selection);
        }
        for (final step in steps) {
          final selection = step.media;
          stepUploads.add(
            selection == null ? null : await _uploadRecipeMedia(selection),
          );
        }
        setState(() => _isUploading = false);
      } else {
        stepUploads.addAll(List<UploadedFile?>.filled(steps.length, null));
      }

      var uploadIndex = 0;
      var sectionIndex = 0;
      final recipeSections = <Map<String, dynamic>>[];
      for (final section in sections) {
        if (section.title.trim().isEmpty && section.contents.isEmpty) continue;
        final contents = <Map<String, dynamic>>[];
        for (
          var stepIndex = 0;
          stepIndex < section.contents.length;
          stepIndex++
        ) {
          final step = section.contents[stepIndex];
          contents.add({
            'contentType': step.media?.kind == RecipeMediaKind.video
                ? 'video'
                : step.contentType,
            'title': step.title,
            'textContent': step.textContent,
            'mediaUrl': stepUploads[uploadIndex++]?.url,
            'durationSeconds': step.durationMinutes == null
                ? null
                : step.durationMinutes! * 60,
            'sortOrder': stepIndex,
          });
        }
        recipeSections.add({
          'title': section.title.trim().isEmpty
              ? 'หัวข้อชุดขั้นตอน ${sectionIndex + 1}'
              : section.title.trim(),
          'description': null,
          'sortOrder': sectionIndex++,
          'isPreview': false,
          'contents': contents,
        });
      }

      final title = _titleController.text.trim();
      final slug = _slugController.text.trim();
      final now = DateTime.now().microsecondsSinceEpoch;
      final draftSlugBase = slug.isEmpty ? 'recipe' : slug;
      final draftSlugSuffix = '-draft-$now';
      final draftSlugMaxLength = 255 - draftSlugSuffix.length;
      final generatedDraftSlug =
          '${draftSlugBase.substring(0, draftSlugBase.length < draftSlugMaxLength ? draftSlugBase.length : draftSlugMaxLength)}$draftSlugSuffix';
      final price = double.tryParse(_priceController.text.trim()) ?? 0;

      final recipe = <String, dynamic>{
        'creatorId': creatorId,
        'title': title.isEmpty && asDraft ? 'สูตรอาหารฉบับร่าง' : title,
        'slug': slug.isEmpty && asDraft ? generatedDraftSlug : slug,
        'shortDescription': _optionalText(_descriptionController.text),
        'coverImageUrl': coverUpload?.url,
        'showImgCommu': _showImgCommu,
        'price': price.toStringAsFixed(2),
        'preparationMinutes': int.tryParse(_preparationController.text.trim()),
        'cookingMinutes': int.tryParse(_cookingController.text.trim()),
        'servingCount': int.tryParse(_servingsController.text.trim()),
        'difficulty': _difficulty,
        'type': 'community',
        'status': asDraft ? 'draft' : 'published',
        'categoryIds': _selectedCategoryIds.toList(),
        'sections': recipeSections,
      };

      await FoodRepository().createCommunityFood(recipe);
      if (!mounted) return false;
      if (asDraft) _showMessage('บันทึกฉบับร่างแล้ว');
      return true;
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _handleBack() async {
    if (_handlingExit || _isBusy || _isSaving) return;
    _handlingExit = true;
    try {
      if (!_hasDraftContent) {
        _popPage(false);
        return;
      }

      final decision = await showDialog<_ExitDecision>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('บันทึกฉบับร่างก่อนออกไหม?'),
          content: const Text(
            'ข้อมูลที่กรอกไว้จะถูกเก็บใน Drafts บนหน้า Profile',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('อยู่ต่อ'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ExitDecision.discard),
              child: const Text('ออกโดยไม่บันทึก'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ExitDecision.saveDraft),
              child: const Text('บันทึกฉบับร่าง'),
            ),
          ],
        ),
      );
      if (!mounted || decision == null) {
        return;
      }
      if (decision == _ExitDecision.saveDraft &&
          !await _persistRecipe(asDraft: true)) {
        return;
      }
      _popPage(false);
    } finally {
      _handlingExit = false;
    }
  }

  void _popPage(bool result) {
    if (!mounted) {
      return;
    }
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCookingSteps() async {
    if (_isBusy || _isSaving) return;
    final draft = await Navigator.of(context).push<RecipeSectionDraft>(
      MaterialPageRoute<RecipeSectionDraft>(
        builder: (_) => CreateCookingStepsPage(initialDraft: _sectionDraft),
      ),
    );
    if (!mounted || draft == null) return;
    setState(() => _sectionDraft = draft);
  }

  Future<void> _pickCoverImage() async {
    final selection = await _pickPendingFile(
      kind: UploadKind.images,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    );
    if (!mounted || selection == null) return;
    setState(() => _coverSelection = selection);
    _showMessage('เลือกไฟล์แล้ว จะอัปโหลดเมื่อเผยแพร่สูตร');
  }

  Future<_PendingUpload?> _pickPendingFile({
    required UploadKind kind,
    required List<String> allowedExtensions,
  }) async {
    if (_isSaving || _isBusy) return null;
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (result == null || result.files.isEmpty) return null;

      final selectedFile = result.files.single;
      final path = selectedFile.path;
      if (path == null) {
        throw Exception('ไม่สามารถเปิดไฟล์ที่เลือกได้');
      }
      final maximumSize = kind == UploadKind.images
          ? 10 * 1024 * 1024
          : 100 * 1024 * 1024;
      if (selectedFile.size < 1 || selectedFile.size > maximumSize) {
        final maximumMb = maximumSize ~/ (1024 * 1024);
        throw Exception('ไฟล์ต้องมีขนาดไม่เกิน $maximumMb MB');
      }

      return _PendingUpload(
        file: File(path),
        name: selectedFile.name,
        kind: kind,
        mimeType: _mimeType(kind, selectedFile.extension),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<UploadedFile> _uploadPendingFile(_PendingUpload selection) {
    return _uploadRepository.upload(
      file: selection.file,
      kind: selection.kind,
      mimeType: selection.mimeType,
    );
  }

  Future<UploadedFile> _uploadRecipeMedia(PendingRecipeUpload selection) {
    return _uploadRepository.upload(
      file: selection.file,
      kind: selection.kind == RecipeMediaKind.video
          ? UploadKind.videos
          : UploadKind.images,
      mimeType: selection.mimeType,
    );
  }

  String _mimeType(UploadKind kind, String? extension) {
    final normalizedExtension = extension?.toLowerCase();
    if (kind == UploadKind.images) {
      return switch (normalizedExtension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => throw Exception('รองรับไฟล์ JPG, PNG, WEBP หรือ GIF เท่านั้น'),
      };
    }
    return switch (normalizedExtension) {
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'mov' => 'video/quicktime',
      _ => throw Exception('รองรับไฟล์ MP4, WEBM หรือ MOV เท่านั้น'),
    };
  }

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'กรอก$label';
    return null;
  }

  String? _nonNegativeNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null || number < 0) {
      return '$labelต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป';
    }
    return null;
  }

  String? _requiredWholeNumber(
    String? value,
    String label, {
    bool mustBePositive = false,
  }) {
    if (value == null || value.trim().isEmpty) return 'กรอก$label';
    final number = int.tryParse(value.trim());
    final minimum = mustBePositive ? 1 : 0;
    if (number == null || number < minimum) {
      return '$labelต้องเป็นจำนวนเต็มตั้งแต่ $minimum ขึ้นไป';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5F0),
        appBar: AppBar(
          title: const Text('สร้างสูตรอาหาร'),
          backgroundColor: const Color(0xFFF6F5F0),
          actions: [
            IconButton(
              onPressed: _isSaving || _isBusy ? null : _saveRecipe,
              tooltip: 'เผยแพร่สูตร',
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              RecipeBasicInfoSection(
                titleController: _titleController,
                slugController: _slugController,
                descriptionController: _descriptionController,
                validator: _requiredText,
              ),

              const SizedBox(height: 22),

              RecipeCoverSection(
                coverFile: _coverSelection?.file,
                fileName: _coverSelection?.name,
                showImgCommu: _showImgCommu,
                isBusy: _isBusy,
                isSaving: _isSaving,
                isPickingFile: _isPickingFile,
                isUploading: _isUploading,
                onPickImage: _pickCoverImage,
                onRemoveImage: () {
                  setState(() => _coverSelection = null);
                },
                onShowImgCommuChanged: (value) {
                  setState(() => _showImgCommu = value);
                },
              ),

              const SizedBox(height: 22),

              RecipeDetailSection(
                priceController: _priceController,
                preparationController: _preparationController,
                cookingController: _cookingController,
                servingsController: _servingsController,
                difficulty: _difficulty,
                showPrice: !widget.isFromCommunity,
                requiredWholeNumber: _requiredWholeNumber,
                nonNegativeNumber: _nonNegativeNumber,
                onDifficultyChanged: (value) {
                  setState(() => _difficulty = value);
                },
              ),

              const SizedBox(height: 22),

              RecipeCategorySection(
                categories: widget.categories,
                selectedCategoryIds: _selectedCategoryIds,
                onCategorySelected: (category) {
                  setState(() {
                    if (!_selectedCategoryIds.contains(category.id)) {
                      _selectedCategoryIds.add(category.id);
                    }
                  });
                },
              ),

              const SizedBox(height: 22),

              RecipeStepsSection(
                sectionCount: _sectionDraft?.sections.length ?? 0,
                stepCount: _sectionDraft?.sections.fold<int>(
                      0,
                      (count, section) =>
                          count + section.contents.length,
                    ) ??
                    0,
                hasDraft: _sectionDraft != null,
                isBusy: _isBusy,
                isSaving: _isSaving,
                onEdit: _openCookingSteps,
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed:
                    _isSaving || _isBusy ? null : _saveRecipe,
                icon: const Icon(Icons.publish_rounded),
                label: Text(
                  _isUploading
                      ? 'กำลังอัปโหลดไฟล์...'
                      : _isSaving
                          ? 'กำลังเผยแพร่...'
                          : 'เผยแพร่สูตรอาหาร',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFCE4D35),
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingUpload {
  const _PendingUpload({
    required this.file,
    required this.name,
    required this.kind,
    required this.mimeType,
  });

  final File file;
  final String name;
  final UploadKind kind;
  final String mimeType;
}

enum _ExitDecision { saveDraft, discard }