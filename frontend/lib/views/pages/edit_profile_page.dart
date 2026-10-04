import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/data/recipe_library_cache.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/image_compressor.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/repositories/upload_repository.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:image_picker/image_picker.dart';

/// แก้โปรไฟล์: เปลี่ยนรูปและชื่อได้ อีเมลแสดงอย่างเดียว
/// บันทึกสำเร็จจะ pop พร้อม [UserProfile] ตัวใหม่ (ยกเลิก = null)
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.profile.displayName,
  );
  final _picker = ImagePicker();
  final _uploadRepository = HttpUploadRepository(baseUrl: ApiConfig.apiBaseUrl);
  final _profileRepository = HttpProfileRepository(
    baseUrl: ApiConfig.apiBaseUrl,
  );

  // รูปที่เลือกใหม่ (ย่อแล้ว) ยังไม่อัปโหลดจนกว่าจะกดบันทึก
  UploadImage? _newAvatar;
  bool _isPicking = false;
  bool _isSaving = false;

  String get _trimmedName => _nameController.text.trim();

  bool get _hasChanges =>
      _newAvatar != null || _trimmedName != widget.profile.displayName;

  @override
  void initState() {
    super.initState();
    // ปุ่มบันทึกเปิด/ปิดตามว่ามีอะไรเปลี่ยนไหม
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isPicking || _isSaving) return;
    setState(() => _isPicking = true);
    try {
      // รูปโปรไฟล์แสดงเล็ก ย่อเหลือ 512px พอ
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      final extension = picked.name.split('.').last.toLowerCase();
      final prepared = await prepareImageForUpload(
        file: File(picked.path),
        name: picked.name,
        mimeType: switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'gif' => 'image/gif',
          _ => 'image/jpeg',
        },
      );
      if (!mounted) return;
      setState(() => _newAvatar = prepared);
    } catch (error) {
      _showMessage('เปิดรูปไม่ได้: $error');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_hasChanges) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final token = await TokenStorage().readAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }

      String? avatarPath;
      final avatar = _newAvatar;
      if (avatar != null) {
        final uploaded = await _uploadRepository.upload(
          file: avatar.file,
          kind: UploadKind.images,
          mimeType: avatar.mimeType,
        );
        // เก็บเป็น path (ไม่ผูกกับ host) backend รับเฉพาะรูปที่อัปโหลดผ่านระบบ
        avatarPath = '/uploads/images/${uploaded.filename}';
      }

      final name = _trimmedName;
      final updated = await _profileRepository.updateProfile(
        token,
        displayName: name == widget.profile.displayName ? null : name,
        avatarPath: avatarPath,
      );

      // ชื่อ/รูปฝังอยู่ในการ์ดสูตร คอมเมนต์ รีวิวที่เก็บไว้ในแอป ล้างให้โหลดใหม่
      FoodRepository.clearCache();
      RecipeLibraryCache.invalidateAll();

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ใช้แสดงข้อผิดพลาดอย่างเดียว (บันทึกสำเร็จจะปิดหน้านี้ไปเลย)
  void _showMessage(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message, type: AppSnackType.error);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _isPicking;

    return PopScope(
      // กำลังบันทึกอยู่ห้ามออก ไม่งั้นอัปโหลดค้างครึ่งทาง
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: ProfileColors.background,
        appBar: RecipeFormStyle.appBar(title: 'Edit profile'),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: busy || !_hasChanges ? null : _save,
            style: RecipeFormStyle.primaryButton().copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? ProfileColors.ink.withValues(alpha: 0.35)
                    : ProfileColors.ink,
              ),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: _AvatarPicker(
                  currentUrl: widget.profile.avatarUrl,
                  newFile: _newAvatar?.file,
                  isPicking: _isPicking,
                  onPressed: busy ? null : _pickAvatar,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: busy ? null : _pickAvatar,
                  style: TextButton.styleFrom(
                    foregroundColor: ProfileColors.ink,
                  ),
                  child: const Text(
                    'เปลี่ยนรูปโปรไฟล์',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              RecipeFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      maxLength: 150,
                      textInputAction: TextInputAction.done,
                      decoration: RecipeFormStyle.input(
                        label: 'ชื่อที่แสดง',
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: RecipeFormStyle.muted,
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'กรอกชื่อที่แสดง'
                          : null,
                    ),
                    const SizedBox(height: 4),
                    // อีเมลใช้ login แก้ไม่ได้
                    TextFormField(
                      initialValue: widget.profile.email,
                      readOnly: true,
                      enabled: false,
                      decoration:
                          RecipeFormStyle.input(
                            label: 'อีเมล',
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: RecipeFormStyle.muted,
                            ),
                          ).copyWith(
                            suffixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: RecipeFormStyle.muted,
                            ),
                            helperText: 'อีเมลใช้สำหรับเข้าสู่ระบบ แก้ไขไม่ได้',
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.currentUrl,
    required this.newFile,
    required this.isPicking,
    required this.onPressed,
  });

  final String? currentUrl;
  final File? newFile;
  final bool isPicking;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final file = newFile;
    final url = currentUrl;
    final Widget image = file != null
        ? Image.file(file, fit: BoxFit.cover)
        : url != null
        ? AppNetworkImage(
            url,
            errorBuilder: (_) =>
                Image.asset(UserProfile.fallbackAvatarAsset, fit: BoxFit.cover),
          )
        : Image.asset(UserProfile.fallbackAvatarAsset, fit: BoxFit.cover);

    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: ProfileColors.accent,
              shape: BoxShape.circle,
            ),
            child: ClipOval(child: image),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ProfileColors.ink,
                shape: BoxShape.circle,
                border: Border.all(color: ProfileColors.background, width: 3),
              ),
              child: isPicking
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
