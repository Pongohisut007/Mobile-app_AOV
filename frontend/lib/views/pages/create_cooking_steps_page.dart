import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';

class CreateCookingStepsPage extends StatefulWidget {
  const CreateCookingStepsPage({super.key, this.initialDraft});

  final RecipeSectionDraft? initialDraft;

  @override
  State<CreateCookingStepsPage> createState() => _CreateCookingStepsPageState();
}

class _CreateCookingStepsPageState extends State<CreateCookingStepsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sectionTitleController;
  late final List<_StepEditor> _steps;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _sectionTitleController = TextEditingController(text: draft?.title ?? '');
    _steps = draft == null || draft.contents.isEmpty
        ? [_StepEditor()]
        : draft.contents.map(_StepEditor.fromDraft).toList();
  }

  @override
  void dispose() {
    _sectionTitleController.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  void _saveDraft() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      RecipeSectionDraft(
        title: _sectionTitleController.text.trim(),
        contents: _steps.map((step) => step.toDraft()).toList(),
      ),
    );
  }

  Future<void> _pickMedia(_StepEditor step) async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      final isVideo = step.mediaKind == RecipeMediaKind.video;
      final extensions = isVideo
          ? const ['mp4', 'webm', 'mov']
          : const ['jpg', 'jpeg', 'png', 'webp', 'gif'];
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;
      if (path == null) throw Exception('ไม่สามารถเปิดไฟล์ที่เลือกได้');
      final maxSize = isVideo ? 100 * 1024 * 1024 : 10 * 1024 * 1024;
      if (file.size < 1 || file.size > maxSize) {
        throw Exception('ไฟล์ต้องมีขนาดไม่เกิน ${maxSize ~/ (1024 * 1024)} MB');
      }

      final kind = isVideo ? RecipeMediaKind.video : RecipeMediaKind.image;
      setState(() {
        step.media = PendingRecipeUpload(
          file: File(path),
          name: file.name,
          kind: kind,
          mimeType: _mimeType(kind, file.extension),
        );
      });
      _showMessage('เลือกไฟล์แล้ว จะอัปโหลดเมื่อเผยแพร่สูตร');
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  String _mimeType(RecipeMediaKind kind, String? extension) {
    if (kind == RecipeMediaKind.image) {
      return switch (extension?.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => throw Exception('รองรับไฟล์ JPG, PNG, WEBP หรือ GIF เท่านั้น'),
      };
    }
    return switch (extension?.toLowerCase()) {
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'mov' => 'video/quicktime',
      _ => throw Exception('รองรับไฟล์ MP4, WEBM หรือ MOV เท่านั้น'),
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'กรอก$label';
    return null;
  }

  String? _minutes(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'ใส่เวลาเป็นจำนวนนาทีตั้งแต่ 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0),
      appBar: AppBar(
        title: const Text('ขั้นตอนการทำอาหาร'),
        backgroundColor: const Color(0xFFF6F5F0),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (var index = 0; index < _steps.length; index++)
              _buildStepCard(index),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _isPickingFile
                    ? null
                    : () => setState(() => _steps.add(_StepEditor())),
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มขั้นตอน'),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isPickingFile ? null : _saveDraft,
              icon: const Icon(Icons.check_rounded),
              label: const Text('บันทึกขั้นตอน'),
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

  Widget _buildStepCard(int index) {
    final step = _steps[index];
    return Container(
      key: ObjectKey(step),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E2DA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ขั้นตอนที่ ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_steps.length > 1)
                IconButton(
                  onPressed: _isPickingFile
                      ? null
                      : () => setState(() => _steps.removeAt(index).dispose()),
                  tooltip: 'ลบขั้นตอน',
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          TextFormField(
            controller: _sectionTitleController,
            decoration: const InputDecoration(
              labelText: 'ชื่อหัวข้อขั้นตอน',
              hintText: 'เช่น วิธีทำ',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _required(value, 'ชื่อหัวข้อขั้นตอน'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: step.title,
            decoration: const InputDecoration(
              labelText: 'ชื่อขั้นตอน',
              hintText: 'เช่น เตรียมหมูและเครื่องปรุง',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _required(value, 'ชื่อขั้นตอน'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: step.description,
            decoration: const InputDecoration(
              labelText: 'วิธีทำ',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            validator: (value) => _required(value, 'วิธีทำ'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: step.contentType,
                  decoration: const InputDecoration(
                    labelText: 'ชนิดขั้นตอน',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('วิธีทำ')),
                    DropdownMenuItem(value: 'tip', child: Text('เคล็ดลับ')),
                    DropdownMenuItem(
                      value: 'warning',
                      child: Text('ข้อควรระวัง'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => step.contentType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: step.durationMinutes,
                  decoration: const InputDecoration(
                    labelText: 'เวลา (นาที)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _minutes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RecipeMediaKind>(
                  initialValue: step.mediaKind,
                  decoration: const InputDecoration(
                    labelText: 'สื่อประกอบ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: RecipeMediaKind.image,
                      child: Text('รูปภาพ'),
                    ),
                    DropdownMenuItem(
                      value: RecipeMediaKind.video,
                      child: Text('คลิปวิดีโอ'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      if (step.mediaKind != value) step.media = null;
                      step.mediaKind = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPickingFile ? null : () => _pickMedia(step),
                  icon: _isPickingFile
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(step.media == null ? 'เลือกไฟล์' : 'เปลี่ยนไฟล์'),
                ),
              ),
            ],
          ),
          if (step.media != null) ...[
            const SizedBox(height: 8),
            if (step.media!.kind == RecipeMediaKind.image)
              _ImagePreview(file: step.media!.file),
            Text(
              step.media!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepEditor {
  _StepEditor({
    String title = '',
    String description = '',
    this.contentType = 'text',
    int? durationMinutes,
    this.media,
    this.mediaKind = RecipeMediaKind.image,
  }) : title = TextEditingController(text: title),
       description = TextEditingController(text: description),
       durationMinutes = TextEditingController(
         text: durationMinutes?.toString() ?? '',
       );

  factory _StepEditor.fromDraft(RecipeContentDraft draft) {
    return _StepEditor(
      title: draft.title,
      description: draft.textContent,
      contentType: draft.contentType,
      durationMinutes: draft.durationMinutes,
      media: draft.media,
      mediaKind: draft.media?.kind ?? RecipeMediaKind.image,
    );
  }

  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController durationMinutes;
  String contentType;
  PendingRecipeUpload? media;
  RecipeMediaKind mediaKind;

  RecipeContentDraft toDraft() {
    return RecipeContentDraft(
      title: title.text.trim(),
      textContent: description.text.trim(),
      contentType: contentType,
      durationMinutes: int.tryParse(durationMinutes.text.trim()),
      media: media,
    );
  }

  void dispose() {
    title.dispose();
    description.dispose();
    durationMinutes.dispose();
  }
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
