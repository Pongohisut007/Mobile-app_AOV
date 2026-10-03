import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/repositories/upload_repository.dart';
import 'package:flutter_application_1/views/pages/create_cooking_steps_page.dart';

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

  bool get _isBusy => _isPickingFile || _isUploading;

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
    if (!_formKey.currentState!.validate()) return;
    if (_coverSelection == null) {
      _showMessage('เลือกรูปตัวอย่างอาหารก่อนเผยแพร่สูตร');
      return;
    }
    if (_isBusy || _isSaving) {
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showMessage('เลือกหมวดหมู่อย่างน้อย 1 หมวด');
      return;
    }
    final sectionDraft = _sectionDraft;
    if (sectionDraft == null || sectionDraft.contents.isEmpty) {
      _showMessage('เพิ่มขั้นตอนการทำอาหารก่อนเผยแพร่สูตร');
      return;
    }
    if (sectionDraft.contents.any(
      (step) =>
          step.sectionTitle.trim().isEmpty ||
          step.title.trim().isEmpty ||
          step.textContent.trim().isEmpty,
    )) {
      _showMessage('กรอกชื่อและรายละเอียดให้ครบทุกขั้นตอน');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final creatorId = await TokenStorage().readUserId();
      if (!mounted) return;
      if (creatorId == null || creatorId.trim().isEmpty) {
        throw Exception('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }

      final hasFilesToUpload =
          _coverSelection != null ||
          sectionDraft.contents.any((step) => step.media != null);
      UploadedFile? coverUpload;
      final stepUploads = <UploadedFile?>[];
      if (hasFilesToUpload) {
        setState(() => _isUploading = true);
        if (_coverSelection case final selection?) {
          coverUpload = await _uploadPendingFile(selection);
        }
        for (final step in sectionDraft.contents) {
          final selection = step.media;
          stepUploads.add(
            selection == null ? null : await _uploadRecipeMedia(selection),
          );
        }
        setState(() => _isUploading = false);
      } else {
        stepUploads.addAll(
          List<UploadedFile?>.filled(sectionDraft.contents.length, null),
        );
      }

      final recipe = <String, dynamic>{
        'creatorId': creatorId,
        'title': _titleController.text.trim(),
        'slug': _slugController.text.trim(),
        'shortDescription': _optionalText(_descriptionController.text),
        'coverImageUrl': coverUpload?.url,
        'showImgCommu': _showImgCommu,
        'price': double.parse(_priceController.text.trim()).toStringAsFixed(2),
        'preparationMinutes': _optionalInt(_preparationController.text),
        'cookingMinutes': _optionalInt(_cookingController.text),
        'servingCount': _optionalInt(_servingsController.text),
        'difficulty': _difficulty,
        'type': 'community',
        'status': 'published',
        'categoryIds': _selectedCategoryIds.toList(),
        'sections': [
          for (var index = 0; index < sectionDraft.contents.length; index++)
            {
              'title': sectionDraft.contents[index].sectionTitle,
              'description': null,
              'sortOrder': index,
              'isPreview': false,
              'contents': [
                {
                  'contentType':
                      sectionDraft.contents[index].media?.kind ==
                          RecipeMediaKind.video
                      ? 'video'
                      : sectionDraft.contents[index].contentType,
                  'title': sectionDraft.contents[index].title,
                  'textContent': sectionDraft.contents[index].textContent,
                  'mediaUrl': stepUploads[index]?.url,
                  'durationSeconds':
                      sectionDraft.contents[index].durationMinutes == null
                      ? null
                      : sectionDraft.contents[index].durationMinutes! * 60,
                  'sortOrder': 0,
                },
              ],
            },
        ],
      };

      await FoodRepository().createCommunityFood(recipe);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
      }
    }
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

  int? _optionalInt(String value, {int multiplier = 1}) {
    final text = value.trim();
    return text.isEmpty ? null : int.parse(text) * multiplier;
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
    return Scaffold(
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
            _sectionHeading('สูตรของคุณ', Icons.menu_book_outlined),
            const SizedBox(height: 14),
            _textField(
              controller: _titleController,
              label: 'ชื่อภาษาไทย',
              validator: (value) => _requiredText(value, 'ชื่อสูตรอาหาร'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _slugController,
              label: 'ชื่อภาษาอังกฤษ',
              hint: 'spicy-basil-chicken',
              validator: (value) {
                final required = _requiredText(value, 'slug');
                if (required != null) return required;
                if (!RegExp(
                  r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
                ).hasMatch(value!.trim())) {
                  return 'ใช้ a-z, 0-9 และเครื่องหมาย - เท่านั้น';
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-z0-9-]')),
              ],
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _descriptionController,
              label: 'คำอธิบาย',
              hint: 'เล่าจุดเด่นหรือรสชาติของเมนูนี้',
              maxLines: 3,
            ),
            const SizedBox(height: 22),
            _sectionHeading('รูปตัวอย่างอาหาร', Icons.image_outlined),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving || _isBusy ? null : _pickCoverImage,
              icon: _isPickingFile || _isUploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(
                _coverSelection == null ? 'เลือกรูปภาพ' : 'เปลี่ยนรูปภาพ',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('แสดงรูปในชุมชน'),
              value: _showImgCommu,
              onChanged: _isSaving || _isBusy
                  ? null
                  : (value) => setState(() => _showImgCommu = value ?? false),
            ),
            if (_coverSelection != null) ...[
              const SizedBox(height: 12),
              _ImagePreview(file: _coverSelection!.file),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _coverSelection!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _coverSelection = null),
                    tooltip: 'ลบรูปภาพ',
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            _sectionHeading('รายละเอียดสูตร', Icons.tune_rounded),
            const SizedBox(height: 12),
            if (!widget.isFromCommunity) ...[
              _textField(
                controller: _priceController,
                label: 'ราคา (บาท)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'กรอกราคา';
                  return _nonNegativeNumber(value, 'ราคา');
                },
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _preparationController,
                    label: 'เตรียม (นาที)',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _requiredWholeNumber(value, 'เวลาเตรียม'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _textField(
                    controller: _cookingController,
                    label: 'ปรุง (นาที)',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _requiredWholeNumber(value, 'เวลาปรุง'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _servingsController,
                    label: 'จำนวนที่รับประทาน',
                    keyboardType: TextInputType.number,
                    validator: (value) => _requiredWholeNumber(
                      value,
                      'จำนวนที่รับประทาน',
                      mustBePositive: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'ระดับความยาก',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null ? 'เลือกระดับความยาก' : null,
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('ง่าย')),
                      DropdownMenuItem(value: 'medium', child: Text('ปานกลาง')),
                      DropdownMenuItem(value: 'hard', child: Text('ยาก')),
                    ],
                    onChanged: (value) => setState(() => _difficulty = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _sectionHeading('หมวดหมู่', Icons.category_outlined),
            const SizedBox(height: 8),
            if (widget.categories.isEmpty)
              const Text('ไม่มีหมวดหมู่ให้เลือก')
            else
              Autocomplete<Category>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();

                  // ถ้าไม่ได้กรอก → แสดงทุก category
                  if (query.isEmpty) {
                    return widget.categories;
                  }

                  // ถ้ากรอก → filter ตามชื่อ
                  return widget.categories.where(
                    (category) => category.name.toLowerCase().contains(query),
                  );
                },

                displayStringForOption: (Category category) => category.name,

                onSelected: (Category category) {
                  setState(() {
                    if (!_selectedCategoryIds.contains(category.id)) {
                      _selectedCategoryIds.add(category.id);
                    }
                  });
                },

                fieldViewBuilder:
                    (
                      BuildContext context,
                      TextEditingController controller,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาหมวดหมู่...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },

                optionsViewBuilder:
                    (
                      BuildContext context,
                      AutocompleteOnSelected<Category> onSelected,
                      Iterable<Category> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 180, // ประมาณ 3 รายการ
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final category = options.elementAt(index);
                                final isSelected = _selectedCategoryIds
                                    .contains(category.id);

                                return ListTile(
                                  dense: true,
                                  title: Text(category.name),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        )
                                      : null,
                                  onTap: () {
                                    onSelected(category);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
              ),
            const SizedBox(height: 22),
            _sectionHeading('ขั้นตอนการทำอาหาร', Icons.restaurant_menu_rounded),
            const SizedBox(height: 12),
            Text(
              _sectionDraft == null
                  ? 'ยังไม่ได้เพิ่มขั้นตอน'
                  : '${_sectionDraft!.contents.length} ขั้นตอน',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _isSaving || _isBusy ? null : _openCookingSteps,
                icon: Icon(
                  _sectionDraft == null ? Icons.add : Icons.edit_outlined,
                ),
                label: Text(
                  _sectionDraft == null ? 'เพิ่มขั้นตอน' : 'แก้ไขขั้นตอน',
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving || _isBusy ? null : _saveRecipe,
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
    );
  }

  Widget _sectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFCE4D35)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      maxLines: maxLines,
      keyboardType:
          keyboardType ??
          (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
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

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE9E6DE),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, size: 36),
          ),
        ),
      ),
    );
  }
}
