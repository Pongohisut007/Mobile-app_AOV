import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';

class RecipeCoverSection extends StatelessWidget {
  const RecipeCoverSection({
    super.key,
    required this.coverFile,
    required this.fileName,
    this.coverUrl,
    required this.showImgCommu,
    required this.isBusy,
    required this.isSaving,
    required this.isPickingFile,
    required this.isUploading,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onShowImgCommuChanged,
    this.showImgCommuOption = true,
  });

  // สูตร official ไม่ได้ขึ้นในชุมชน จึงซ่อน checkbox นี้
  final bool showImgCommuOption;

  final File? coverFile;
  final String? fileName;
  // รูปเดิมที่อัปโหลดไว้แล้ว (ตอนแก้ไขสูตร) แสดงเมื่อยังไม่ได้เลือกไฟล์ใหม่
  final String? coverUrl;
  final bool showImgCommu;

  final bool isBusy;
  final bool isSaving;
  final bool isPickingFile;
  final bool isUploading;

  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final ValueChanged<bool> onShowImgCommuChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = isSaving || isBusy;
    final hasCover = coverFile != null || coverUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RecipeFormSectionHeading(
          title: 'รูปตัวอย่างอาหาร',
          icon: Icons.image_outlined,
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: disabled ? null : onPickImage,
          icon: isPickingFile || isUploading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.upload_file_rounded),
          label: Text(
            hasCover
                ? 'เปลี่ยนรูปภาพ'
                : 'เลือกรูปภาพ',
          ),
        ),

        if (hasCover) ...[
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImage(
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    color: const Color(0xFFE9E6DE),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 36,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: Text(
                  coverFile == null ? 'รูปเดิม' : fileName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: disabled
                    ? null
                    : onRemoveImage,
                tooltip: 'ลบรูปภาพ',
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          ),
        ],

        if (showImgCommuOption)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('แสดงรูปในชุมชน'),
            value: showImgCommu,
            onChanged: disabled
                ? null
                : (value) {
                    onShowImgCommuChanged(value ?? false);
                  },
          ),
      ],
    );
  }

  Widget _buildImage({required ImageErrorWidgetBuilder errorBuilder}) {
    final file = coverFile;
    if (file != null) {
      return Image.file(file, fit: BoxFit.cover, errorBuilder: errorBuilder);
    }
    return Image.network(
      coverUrl!,
      fit: BoxFit.cover,
      errorBuilder: errorBuilder,
    );
  }
}
