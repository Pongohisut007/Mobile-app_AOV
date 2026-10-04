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
import 'package:flutter_application_1/widgets/create_food/recipe_steps_section.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_type_section.dart';

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
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _preparationController = TextEditingController();
  final _cookingController = TextEditingController();
  final _servingsController = TextEditingController();
  final _selectedCategoryIds = <String>{};
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
    final food = widget.initialFood;
    if (food == null) return;

    _loadIsCreator();

    _titleController.text = food.name;
    _slugController.text = food.slug;
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
        _slugController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _coverSelection != null ||
        _existingCoverUrl != null ||
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
                        step.hasMedia,
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
    setState(() {
      _isSaving = true;
      _isSavingDraft = asDraft;
    });
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
      // community เป็นสูตรฟรี ไม่มีช่องราคา จึงส่ง 0 เสมอ
      final price = _type == 'community'
          ? 0.0
          : double.tryParse(_priceController.text.trim()) ?? 0;

      final recipe = <String, dynamic>{
        if (!_isEditing) 'creatorId': creatorId,
        'title': title.isEmpty && asDraft ? 'สูตรอาหารฉบับร่าง' : title,
        'slug': slug.isEmpty && asDraft ? generatedDraftSlug : slug,
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
        _showMessage('บันทึกฉบับร่างแล้ว', type: AppSnackType.success);
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

  // โหมดแก้ไขไม่บันทึกเป็นฉบับร่าง เพราะจะทำให้สูตรที่เผยแพร่แล้วกลายเป็น draft
  Future<void> _confirmDiscardEdit() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยกเลิกการแก้ไขไหม?'),
        content: const Text('การแก้ไขที่ยังไม่ได้บันทึกจะหายไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('แก้ไขต่อ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ออกโดยไม่บันทึก'),
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
      'เลือกไฟล์แล้ว จะอัปโหลดเมื่อเผยแพร่สูตร',
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
        throw Exception('ไม่สามารถเปิดไฟล์ที่เลือกได้');
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
        throw Exception('ไฟล์ต้องมีขนาดไม่เกิน $maximumMb MB');
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
        backgroundColor: RecipeFormStyle.background,
        appBar: RecipeFormStyle.appBar(
          title: _isEditing ? 'แก้ไขสูตรอาหาร' : 'สร้างสูตรอาหาร',
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
                slugController: _slugController,
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
                        ? 'กำลังอัปโหลดไฟล์...'
                        : _isSaving
                        ? (_isEditing ? 'กำลังบันทึก...' : 'กำลังเผยแพร่...')
                        : (_isEditing ? 'บันทึกการแก้ไข' : 'เผยแพร่สูตรอาหาร'),
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
                  ? (_isUploading ? 'กำลังอัปโหลด...' : 'กำลังบันทึก...')
                  : 'บันทึกการแก้ไข',
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
                  ? (_isUploading ? 'กำลังอัปโหลด...' : 'กำลังเผยแพร่...')
                  : 'เผยแพร่',
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
