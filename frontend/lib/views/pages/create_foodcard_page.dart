import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/image_compressor.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/repositories/upload_repository.dart';
import 'package:flutter_application_1/views/pages/create_cooking_steps_page.dart';

import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_basic_info_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_cover_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_detail_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_category_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_ingredients_section.dart';
import 'package:flutter_application_1/models/recipe_ingredient.dart';
import 'package:flutter_application_1/repositories/ingredient_repository.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_steps_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_type_section.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class CreateFoodcardPage extends StatefulWidget {
  const CreateFoodcardPage({
    super.key,
    required this.categories,
    this.isFromCommunity = false,
    this.initialFood,
  });

  final List<Category> categories;
  final bool isFromCommunity;

  /// ถ้าส่งมา หน้านี้จะเป็นโหมดแก้ไข: กรอกข้อมูลเดิมไว้ให้ และบันทึกด้วย PATCH
  final Food? initialFood;

  @override
  State<CreateFoodcardPage> createState() => _CreateFoodcardPageState();
}

class _CreateFoodcardPageState extends State<CreateFoodcardPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _preparationController = TextEditingController();
  final _cookingController = TextEditingController();
  final _servingsController = TextEditingController();
  final _selectedCategoryIds = <String>{};
  // วัตถุดิบของสูตร (ลำดับในรายการ = ลำดับที่แสดง) กับคลังไว้ให้เลือก
  List<RecipeIngredientLine> _ingredients = const [];
  List<IngredientOption> _ingredientCatalog = const [];
  final _uploadRepository = HttpUploadRepository(baseUrl: ApiConfig.apiBaseUrl);

  String? _difficulty;
  late String _type = widget.isFromCommunity ? 'community' : 'official';
  bool _isCreator = false;
  RecipeSectionDraft? _sectionDraft;
  _PendingUpload? _coverSelection;
  String? _existingCoverUrl;
  bool _showImgCommu = false;
  bool _isPickingFile = false;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isSavingDraft = false;
  bool _canPop = false;
  bool _handlingExit = false;

  bool get _isBusy => _isPickingFile || _isUploading;
  bool get _isEditing => widget.initialFood != null;
  bool get _isEditingDraft => widget.initialFood?.status == 'draft';

  // เปลี่ยน type ได้เฉพาะตอนแก้ไขสูตรที่ยังไม่ publish และ user ต้องเป็น creator
  // (backend เช็คซ้ำ)
  bool get _canChangeType =>
      _isEditing && widget.initialFood?.status != 'published' && _isCreator;

  @override
  void initState() {
    super.initState();
    _loadIngredientCatalog();
    final food = widget.initialFood;
    if (food == null) return;

    _loadIsCreator();

    _titleController.text = food.name;
    _titleEnController.text = food.titleEn ?? '';
    _descriptionController.text = food.description;
    _priceController.text = _formatNumber(food.price);
    _preparationController.text = food.preparationMinutes?.toString() ?? '';
    _cookingController.text = food.cookingMinutes?.toString() ?? '';
    _servingsController.text = food.servingCount?.toString() ?? '';
    _difficulty = food.difficulty;
    _showImgCommu = food.showImgCommu;
    final coverUrl = food.filePathImage.trim();
    _existingCoverUrl = coverUrl.isEmpty ? null : coverUrl;
    // เก็บเฉพาะหมวดที่ยังมีอยู่ในรายการ ไม่งั้นจะเลือก/ลบไม่ได้จากหน้าจอ
    final availableIds = widget.categories.map((category) => category.id);
    _selectedCategoryIds.addAll(food.categoryIds.where(availableIds.contains));
    if (food.steps.isNotEmpty) {
      _sectionDraft = RecipeSectionDraft.fromSteps(food.steps);
    }
    _ingredients = food.ingredients;
  }

  // โหลดไม่ได้ก็ยังพิมพ์ชื่อวัตถุดิบเองได้ (แค่ไม่มีตัวเลือกขึ้น)
  Future<void> _loadIngredientCatalog() async {
    final catalog = await IngredientRepository().fetchAll();
    if (!mounted) return;
    setState(() => _ingredientCatalog = catalog);
  }

  Future<void> _loadIsCreator() async {
    try {
      final token = await TokenStorage().readAccessToken();
      if (token == null || token.trim().isEmpty) return;
      final profile = await HttpProfileRepository(
        baseUrl: ApiConfig.apiBaseUrl,
      ).fetchProfile(token);
      if (!mounted) return;
      setState(() => _isCreator = profile.role == 'creator');
    } catch (_) {
      // โหลดโปรไฟล์ไม่ได้ก็แค่ไม่แสดง dropdown ประเภทสูตร
    }
  }

  static String _formatNumber(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  bool get _hasDraftContent {
    final sectionDraft = _sectionDraft;
    return _titleController.text.trim().isNotEmpty ||
        _titleEnController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _coverSelection != null ||
        _existingCoverUrl != null ||
        _preparationController.text.trim().isNotEmpty ||
        _cookingController.text.trim().isNotEmpty ||
        _servingsController.text.trim().isNotEmpty ||
        _difficulty != null ||
        _selectedCategoryIds.isNotEmpty ||
        _ingredients.isNotEmpty ||
        _showImgCommu ||
        (sectionDraft?.sections.any(
              (section) =>
                  section.title.trim().isNotEmpty ||
                  section.contents.any(
                    (step) =>
                        step.title.trim().isNotEmpty ||
                        step.textContent.trim().isNotEmpty ||
                        step.durationMinutes != null ||
                        step.hasMedia,
                  ),
            ) ??
            false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleEnController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationController.dispose();
    _cookingController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  /// บันทึกการแก้ไขฉบับร่าง ไม่บังคับกรอกครบ สถานะยังเป็น draft
  Future<void> _saveDraftEdit() async {
    if (_isBusy || _isSaving) return;
    if (!await _persistRecipe(asDraft: true) || !mounted) return;
    _popPage(true);
  }

  Future<void> _saveRecipe() async {
    if (_isBusy || _isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_coverSelection == null && _existingCoverUrl == null) {
      _showMessage(context.l10n.pickCoverBeforePublish);
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showMessage(context.l10n.pickAtLeastOneCategory);
      return;
    }
    final sectionDraft = _sectionDraft;
    if (sectionDraft == null ||
        sectionDraft.sections.isEmpty ||
        sectionDraft.sections.any((section) => section.contents.isEmpty)) {
      _showMessage(context.l10n.addStepsBeforePublish);
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
      _showMessage(context.l10n.completeAllSteps);
      return;
    }
    if (!await _persistRecipe(asDraft: false) || !mounted) return;
    _popPage(true);
  }

  Future<bool> _persistRecipe({required bool asDraft}) async {
    if (_isBusy || _isSaving) return false;
    setState(() {
      _isSaving = true;
      _isSavingDraft = asDraft;
    });
    try {
      // เจ้าของสูตรคือคนที่ login (backend อ่านจาก token) แค่เช็กว่ายัง login อยู่
      final creatorId = await TokenStorage().readUserId();
      if (!mounted) return false;
      if (creatorId == null || creatorId.trim().isEmpty) {
        throw Exception(appL10n.sessionExpired);
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
            'mediaUrl':
                stepUploads[uploadIndex++]?.url ?? step.existingMediaUrl,
            'durationSeconds': step.durationMinutes == null
                ? null
                : step.durationMinutes! * 60,
            'sortOrder': stepIndex,
          });
        }
        recipeSections.add({
          'title': section.title.trim().isEmpty
              ? appL10n.defaultSectionTitle(sectionIndex + 1)
              : section.title.trim(),
          'description': null,
          'sortOrder': sectionIndex++,
          'isPreview': false,
          'contents': contents,
        });
      }

      final title = _titleController.text.trim();
      final titleEn = _optionalText(_titleEnController.text);
      // community เป็นสูตรฟรี ไม่มีช่องราคา จึงส่ง 0 เสมอ
      final price = _type == 'community'
          ? 0.0
          : double.tryParse(_priceController.text.trim()) ?? 0;

      final recipe = <String, dynamic>{
        'title': title.isEmpty && asDraft ? appL10n.draftRecipeTitle : title,
        'titleEn': titleEn,
        'slug': _buildSlug(titleEn, asDraft: asDraft),
        'shortDescription': _optionalText(_descriptionController.text),
        'coverImageUrl': coverUpload?.url ?? _existingCoverUrl,
        // official ไม่มี checkbox นี้ ส่ง false กันค่าเก่าค้างตอนเปลี่ยน type
        'showImgCommu': _type == 'community' && _showImgCommu,
        'price': price.toStringAsFixed(2),
        'preparationMinutes': int.tryParse(_preparationController.text.trim()),
        'cookingMinutes': int.tryParse(_cookingController.text.trim()),
        'servingCount': int.tryParse(_servingsController.text.trim()),
        'difficulty': _difficulty,
        if (!_isEditing || _canChangeType) 'type': _type,
        'status': asDraft ? 'draft' : 'published',
        'categoryIds': _selectedCategoryIds.toList(),
        'ingredients': [for (final item in _ingredients) item.toPayload()],
        'sections': recipeSections,
      };

      final editingFood = widget.initialFood;
      if (editingFood != null) {
        await FoodRepository().updateFood(editingFood.idfoods, recipe);
      } else {
        await FoodRepository().createCommunityFood(recipe);
      }
      if (!mounted) return false;
      if (asDraft) {
        _showMessage(context.l10n.draftSaved, type: AppSnackType.success);
      }
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

      if (_isEditing) {
        await _confirmDiscardEdit();
        return;
      }

      final decision = await showDialog<_ExitDecision>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.saveDraftBeforeLeaving),
          content: Text(context.l10n.saveDraftBeforeLeavingMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(context.l10n.stay),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ExitDecision.discard),
              child: Text(context.l10n.leaveWithoutSaving),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ExitDecision.saveDraft),
              child: Text(context.l10n.saveDraft),
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

  // โหมดแก้ไขไม่บันทึกเป็นฉบับร่าง เพราะจะทำให้สูตรที่เผยแพร่แล้วกลายเป็น draft
  Future<void> _confirmDiscardEdit() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.discardEditsTitle),
        content: Text(context.l10n.discardEditsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.leaveWithoutSaving),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    _popPage(false);
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

  // ส่วนใหญ่เป็นข้อความเตือน/ผิดพลาด ข้อความสำเร็จต้องระบุ type เอง
  void _showMessage(String message, {AppSnackType type = AppSnackType.error}) {
    showAppSnackBar(context, message, type: type);
  }

  Future<void> _openCookingSteps() async {
    if (_isBusy || _isSaving) return;
    final draft = await Navigator.of(context).push<RecipeSectionDraft>(
      MaterialPageRoute<RecipeSectionDraft>(
        builder: (_) => CreateCookingStepsPage(initialDraft: _sectionDraft),
      ),
    );
    if (!mounted || draft == null) return;
    // ลบหมดแล้ว ให้กลับเป็นสถานะยังไม่มีขั้นตอน
    setState(() => _sectionDraft = draft.sections.isEmpty ? null : draft);
  }

  Future<void> _pickCoverImage() async {
    final selection = await _pickPendingFile(
      kind: UploadKind.images,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    );
    if (!mounted || selection == null) return;
    setState(() => _coverSelection = selection);
    _showMessage(
      context.l10n.fileSelectedWillUpload,
      type: AppSnackType.success,
    );
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
        throw Exception(appL10n.cannotOpenSelectedFile);
      }

      var file = File(path);
      var name = selectedFile.name;
      var mimeType = _mimeType(kind, selectedFile.extension);
      var size = selectedFile.size;
      // ย่อรูปก่อน แล้วค่อยเช็กขนาด รูปต้นฉบับใหญ่เกินแต่ย่อแล้วผ่านก็ใช้ได้
      if (kind == UploadKind.images) {
        final prepared = await prepareImageForUpload(
          file: file,
          name: name,
          mimeType: mimeType,
        );
        file = prepared.file;
        name = prepared.name;
        mimeType = prepared.mimeType;
        size = prepared.size;
      }

      final maximumSize = kind == UploadKind.images
          ? 10 * 1024 * 1024
          : 100 * 1024 * 1024;
      if (size < 1 || size > maximumSize) {
        final maximumMb = maximumSize ~/ (1024 * 1024);
        throw Exception(appL10n.fileTooLarge(maximumMb));
      }

      return _PendingUpload(
        file: file,
        name: name,
        kind: kind,
        mimeType: mimeType,
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
        _ => throw Exception(appL10n.imageTypesOnly),
      };
    }
    return switch (normalizedExtension) {
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'mov' => 'video/quicktime',
      _ => throw Exception(appL10n.videoTypesOnly),
    };
  }

  /// slug ไม่ให้ผู้ใช้กรอกแล้ว สร้างจากชื่ออังกฤษ + เวลา (กันซ้ำกับสูตรอื่น)
  /// แก้สูตรเดิมใช้ slug เดิม ยกเว้นฉบับร่างที่กำลังจะเผยแพร่ ได้ slug ใหม่ที่ไม่มีคำว่า draft
  String _buildSlug(String? titleEn, {required bool asDraft}) {
    final existing = widget.initialFood?.slug ?? '';
    if (existing.isNotEmpty && (asDraft || !existing.contains('-draft-'))) {
      return existing;
    }
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = asDraft ? '-draft-$stamp' : '-$stamp';
    var base = (titleEn ?? '')
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.isEmpty) base = 'recipe';
    final maxBase = 255 - suffix.length;
    if (base.length > maxBase) base = base.substring(0, maxBase);
    return '$base$suffix';
  }

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.fieldRequired(label);
    }
    return null;
  }

  String? _nonNegativeNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null || number < 0) {
      return context.l10n.fieldMustBeNonNegative(label);
    }
    return null;
  }

  String? _requiredWholeNumber(
    String? value,
    String label, {
    bool mustBePositive = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.fieldRequired(label);
    }
    final number = int.tryParse(value.trim());
    final minimum = mustBePositive ? 1 : 0;
    if (number == null || number < minimum) {
      return context.l10n.fieldMustBeWholeNumber(label, minimum);
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
        backgroundColor: RecipeFormStyle.background,
        appBar: RecipeFormStyle.appBar(
          title: _isEditing
              ? context.l10n.editRecipe
              : context.l10n.createRecipe,
        ),
        // ปุ่มเผยแพร่/บันทึกติดล่างจอเสมอ ไม่ต้องเลื่อนลงไปหา
        bottomNavigationBar: _buildBottomActions(),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              RecipeBasicInfoSection(
                titleController: _titleController,
                titleEnController: _titleEnController,
                descriptionController: _descriptionController,
                validator: _requiredText,
              ),

              RecipeCoverSection(
                coverFile: _coverSelection?.file,
                fileName: _coverSelection?.name,
                coverUrl: _existingCoverUrl,
                showImgCommu: _showImgCommu,
                showImgCommuOption: _type == 'community',
                isBusy: _isBusy,
                isSaving: _isSaving,
                isPickingFile: _isPickingFile,
                isUploading: _isUploading,
                onPickImage: _pickCoverImage,
                onRemoveImage: () {
                  setState(() {
                    _coverSelection = null;
                    _existingCoverUrl = null;
                  });
                },
                onShowImgCommuChanged: (value) {
                  setState(() => _showImgCommu = value);
                },
              ),

              RecipeDetailSection(
                priceController: _priceController,
                preparationController: _preparationController,
                cookingController: _cookingController,
                servingsController: _servingsController,
                difficulty: _difficulty,
                showPrice: _type == 'official',
                requiredWholeNumber: _requiredWholeNumber,
                nonNegativeNumber: _nonNegativeNumber,
                onDifficultyChanged: (value) {
                  setState(() => _difficulty = value);
                },
              ),

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
                onCategoryRemoved: _isSaving || _isBusy
                    ? null
                    : (category) => setState(
                        () => _selectedCategoryIds.remove(category.id),
                      ),
              ),

              RecipeIngredientsSection(
                ingredients: _ingredients,
                catalog: _ingredientCatalog,
                enabled: !_isSaving && !_isBusy,
                onChanged: (value) => setState(() => _ingredients = value),
              ),

              if (_canChangeType)
                RecipeTypeSection(
                  type: _type,
                  onTypeChanged: (value) => setState(() => _type = value),
                ),

              RecipeStepsSection(
                sectionCount: _sectionDraft?.sections.length ?? 0,
                stepCount:
                    _sectionDraft?.sections.fold<int>(
                      0,
                      (count, section) => count + section.contents.length,
                    ) ??
                    0,
                hasDraft: _sectionDraft != null,
                isBusy: _isBusy,
                isSaving: _isSaving,
                onEdit: _openCookingSteps,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // แถบปุ่มล่างจอ: ฉบับร่างมี 2 ปุ่ม (บันทึก/เผยแพร่) นอกนั้นปุ่มเดียว
  Widget _buildBottomActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _isEditingDraft
              ? _buildDraftActions()
              : FilledButton.icon(
                  onPressed: _isSaving || _isBusy ? null : _saveRecipe,
                  icon: _isSaving
                      ? const _ButtonSpinner()
                      : Icon(
                          _isEditing
                              ? Icons.check_rounded
                              : Icons.publish_rounded,
                        ),
                  label: Text(
                    _isUploading
                        ? context.l10n.uploadingFiles
                        : _isSaving
                        ? (_isEditing
                              ? context.l10n.saving
                              : context.l10n.publishing)
                        : (_isEditing
                              ? context.l10n.saveChanges
                              : context.l10n.publishRecipe),
                  ),
                  style: RecipeFormStyle.primaryButton(),
                ),
        ),
      ),
    );
  }

  // ฉบับร่าง: บันทึกได้โดยไม่ต้องกรอกครบ หรือเผยแพร่ (ตรวจครบทุกช่อง)
  Widget _buildDraftActions() {
    final disabled = _isSaving || _isBusy;
    final savingDraft = _isSaving && _isSavingDraft;
    final publishing = _isSaving && !_isSavingDraft;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: disabled ? null : _saveDraftEdit,
            icon: savingDraft
                ? const _ButtonSpinner(color: RecipeFormStyle.primary)
                : const Icon(Icons.save_outlined),
            label: Text(
              savingDraft
                  ? (_isUploading
                        ? context.l10n.uploading
                        : context.l10n.saving)
                  : context.l10n.saveChanges,
            ),
            style: RecipeFormStyle.secondaryButton(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: disabled ? null : _saveRecipe,
            icon: publishing
                ? const _ButtonSpinner()
                : const Icon(Icons.publish_rounded),
            label: Text(
              publishing
                  ? (_isUploading
                        ? context.l10n.uploading
                        : context.l10n.publishing)
                  : context.l10n.publish,
            ),
            style: RecipeFormStyle.primaryButton(),
          ),
        ),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
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
