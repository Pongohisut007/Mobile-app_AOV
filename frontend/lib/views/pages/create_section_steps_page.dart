import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';

class CreateSectionStepsPage extends StatefulWidget {
  const CreateSectionStepsPage({
    super.key,
    required this.sectionTitle,
    required this.firstStepNumber,
    required this.initialContents,
  });

  final String sectionTitle;
  final int firstStepNumber;
  final List<RecipeContentDraft> initialContents;

  @override
  State<CreateSectionStepsPage> createState() => _CreateSectionStepsPageState();
}

class _CreateSectionStepsPageState extends State<CreateSectionStepsPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<_StepEditor> _steps;
  bool _isPickingFile = false;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _steps = widget.initialContents.isEmpty
        ? [_StepEditor()]
        : widget.initialContents.map(_StepEditor.fromDraft).toList();
  }

  @override
  void dispose() {
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  /// Collect current step data as drafts without validation.
  /// ขั้นตอนที่ไม่ได้กรอกอะไรเลย (เช่นการ์ดเปล่าที่สร้างให้อัตโนมัติ) จะไม่ถูกนับ
  List<RecipeContentDraft> _collectDrafts() {
    return _steps
        .where((step) => !step.isBlank)
        .map((step) => step.toDraft())
        .toList();
  }

  /// Auto-save: pop the current drafts back to the parent page.
  void _autoSaveAndPop() {
    // กันกดย้อนกลับซ้ำระหว่าง animation ซึ่งจะไป pop หน้าก่อนหน้าด้วย
    if (_isPopping) return;
    _isPopping = true;
    Navigator.of(context).pop(_collectDrafts());
  }

  Future<void> _pickMedia(_StepEditor step) async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
      const videoExtensions = ['mp4', 'webm', 'mov'];
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [...imageExtensions, ...videoExtensions],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;
      if (path == null) throw Exception('ไม่สามารถเปิดไฟล์ที่เลือกได้');
      final extension = file.extension?.toLowerCase();
      final isVideo = videoExtensions.contains(extension);
      if (!isVideo && !imageExtensions.contains(extension)) {
        throw Exception('รองรับไฟล์รูปภาพหรือวิดีโอเท่านั้น');
      }
      final maxSize = isVideo ? 100 * 1024 * 1024 : 10 * 1024 * 1024;
      if (file.size < 1 || file.size > maxSize) {
        throw Exception('ไฟล์ต้องมีขนาดไม่เกิน ${maxSize ~/ (1024 * 1024)} MB');
      }

      final kind = isVideo ? RecipeMediaKind.video : RecipeMediaKind.image;
      setState(() {
        step.existingMediaUrl = null;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _autoSaveAndPop();
      },
      child: Scaffold(
        backgroundColor: RecipeFormStyle.background,
        appBar: RecipeFormStyle.appBar(
          title: widget.sectionTitle,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'กลับ (บันทึกอัตโนมัติ)',
            onPressed: _autoSaveAndPop,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              for (var index = 0; index < _steps.length; index++)
                _buildStepCard(index),
              RecipeAddButton(
                label: 'เพิ่มขั้นตอน',
                onPressed: _isPickingFile
                    ? null
                    : () => setState(() => _steps.add(_StepEditor())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(int index) {
    final step = _steps[index];
    final number = widget.firstStepNumber + index;
    return Container(
      key: ObjectKey(step),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RecipeFormStyle.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวการ์ด: เลขขั้นตอนในวงกลม + ชื่อย่อ + ปุ่มลบ/พับ
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: RecipeFormStyle.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: RecipeFormStyle.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ขั้นตอนที่ $number',
                      style: const TextStyle(
                        color: RecipeFormStyle.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // พับอยู่: โชว์ชื่อขั้นตอนไว้ให้รู้ว่าการ์ดนี้คืออะไร
                    if (!step.isExpanded && step.title.text.trim().isNotEmpty)
                      Text(
                        step.title.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RecipeFormStyle.muted,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
              if (_steps.length > 1)
                IconButton(
                  onPressed: _isPickingFile
                      ? null
                      : () => setState(() => _steps.removeAt(index).dispose()),
                  visualDensity: VisualDensity.compact,
                  color: RecipeFormStyle.muted,
                  tooltip: 'ลบขั้นตอน',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              IconButton(
                onPressed: () =>
                    setState(() => step.isExpanded = !step.isExpanded),
                visualDensity: VisualDensity.compact,
                color: RecipeFormStyle.muted,
                tooltip: step.isExpanded ? 'พับรายละเอียด' : 'ขยายรายละเอียด',
                icon: Icon(
                  step.isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),
          if (step.isExpanded)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildStepFields(step),
            ),
        ],
      ),
    );
  }

  Widget _buildStepFields(_StepEditor step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        TextFormField(
          controller: step.title,
          decoration: RecipeFormStyle.input(
            label: 'ชื่อขั้นตอนย่อย',
            hint: 'เช่น เตรียมหมูและเครื่องปรุง',
          ),
          validator: (value) => _required(value, 'ชื่อขั้นตอนย่อย'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: step.description,
          decoration: RecipeFormStyle.input(
            label: 'วิธีทำ',
            hint: 'อธิบายสิ่งที่ต้องทำในขั้นตอนนี้',
            alignLabelWithHint: true,
          ),
          minLines: 3,
          maxLines: 6,
          validator: (value) => _required(value, 'วิธีทำ'),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: step.contentType,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: RecipeFormStyle.muted,
                ),
                decoration: RecipeFormStyle.input(label: 'ชนิดขั้นตอน'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('วิธีทำ')),
                  DropdownMenuItem(value: 'tip', child: Text('เคล็ดลับ')),
                  DropdownMenuItem(
                    value: 'warning',
                    child: Text('ข้อควรระวัง'),
                  ),
                  DropdownMenuItem(value: 'image', child: Text('รูปภาพ')),
                  DropdownMenuItem(value: 'video', child: Text('คลิปวิดีโอ')),
                ],
                validator: (value) {
                  if ((value == 'image' || value == 'video') &&
                      !step.hasMedia) {
                    return 'เลือกไฟล์รูปภาพหรือวิดีโอ';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    step.contentType = value;
                    if (value != 'image' && value != 'video') {
                      step.media = null;
                      step.existingMediaUrl = null;
                    } else if (step.existingMediaUrl != null &&
                        step.media == null) {
                      // ไม่รู้ชนิดไฟล์เดิมแน่ชัด ให้เลือกไฟล์ใหม่เมื่อเปลี่ยนชนิด
                      step.existingMediaUrl = null;
                    } else if (step.media != null &&
                        value !=
                            (step.media!.kind == RecipeMediaKind.video
                                ? 'video'
                                : 'image')) {
                      step.media = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: step.durationMinutes,
                decoration: RecipeFormStyle.input(
                  label: 'เวลา',
                  suffixText: 'นาที',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _minutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMediaPicker(step),
        if (step.media != null) ...[
          const SizedBox(height: 10),
          if (step.media!.kind == RecipeMediaKind.image) ...[
            _ImagePreview(file: step.media!.file),
            const SizedBox(height: 6),
          ],
          Text(
            step.media!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RecipeFormStyle.muted,
              fontSize: 12.5,
            ),
          ),
        ] else if (step.existingMediaUrl case final mediaUrl?) ...[
          const SizedBox(height: 10),
          if (step.contentType == 'video')
            const Row(
              children: [
                Icon(Icons.videocam_outlined, color: RecipeFormStyle.muted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ใช้คลิปวิดีโอเดิม',
                    style: TextStyle(color: RecipeFormStyle.muted),
                  ),
                ),
              ],
            )
          else
            _ImagePreview(url: mediaUrl),
        ],
      ],
    );
  }

  // แถบเลือกไฟล์: ไอคอนในวงกลม + ข้อความ เต็มความกว้าง
  Widget _buildMediaPicker(_StepEditor step) {
    final hasMedia = step.hasMedia;
    return Material(
      color: RecipeFormStyle.fieldFill,
      borderRadius: BorderRadius.circular(RecipeFormStyle.fieldRadius),
      child: InkWell(
        onTap: _isPickingFile ? null : () => _pickMedia(step),
        borderRadius: BorderRadius.circular(RecipeFormStyle.fieldRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _isPickingFile
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: RecipeFormStyle.primary,
                        ),
                      )
                    : Icon(
                        hasMedia
                            ? Icons.swap_horiz_rounded
                            : Icons.perm_media_outlined,
                        size: 20,
                        color: RecipeFormStyle.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasMedia ? 'เปลี่ยนไฟล์' : 'เลือกรูปภาพหรือวิดีโอ',
                      style: const TextStyle(
                        color: RecipeFormStyle.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'รูปไม่เกิน 10 MB · วิดีโอไม่เกิน 100 MB',
                      style: TextStyle(
                        color: RecipeFormStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: RecipeFormStyle.muted,
              ),
            ],
          ),
        ),
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
    this.existingMediaUrl,
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
      existingMediaUrl: draft.existingMediaUrl,
    );
  }

  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController durationMinutes;
  String contentType;
  PendingRecipeUpload? media;
  String? existingMediaUrl;
  bool isExpanded = true;

  bool get hasMedia => media != null || existingMediaUrl != null;

  bool get isBlank =>
      title.text.trim().isEmpty &&
      description.text.trim().isEmpty &&
      durationMinutes.text.trim().isEmpty &&
      !hasMedia;

  RecipeContentDraft toDraft() {
    return RecipeContentDraft(
      title: title.text.trim(),
      textContent: description.text.trim(),
      contentType: contentType,
      durationMinutes: int.tryParse(durationMinutes.text.trim()),
      media: media,
      existingMediaUrl: media == null ? existingMediaUrl : null,
    );
  }

  void dispose() {
    title.dispose();
    description.dispose();
    durationMinutes.dispose();
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.file, this.url})
    : assert(file != null || url != null);

  final File? file;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: file != null
            ? Image.file(file!, fit: BoxFit.cover, errorBuilder: _broken)
            : Image.network(url!, fit: BoxFit.cover, errorBuilder: _broken),
      ),
    );
  }

  static Widget _broken(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: const Color(0xFFE9E6DE),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, size: 36),
    );
  }
}
