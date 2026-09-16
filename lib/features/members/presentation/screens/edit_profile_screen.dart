import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_provider_util.dart';
import '../../domain/models/member_profile.dart';
import '../../providers/member_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final MemberProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.profile.fullName);
    _phoneController =
        TextEditingController(text: widget.profile.phoneNumber);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      imageQuality: 70, // heavily compressed to stay under 1MB limit for Firestore
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    String? photoUrl = widget.profile.photoUrl;

    if (_selectedImage != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await _selectedImage!.readAsBytes();
        final base64String = base64Encode(bytes);
        photoUrl = 'data:image/jpeg;base64,$base64String';
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
        setState(() => _isUploadingImage = false);
        return;
      }
      setState(() => _isUploadingImage = false);
    }

    ref.read(editProfileControllerProvider.notifier).updateProfile(
          uid: widget.profile.uid,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          photoUrl: photoUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(editProfileControllerProvider, (_, state) {
      state.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
      );
    });

    final state = ref.watch(editProfileControllerProvider);
    final isBusy = state.isLoading || _isUploadingImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar placeholder (with upload) ───────────────
              Center(
                child: GestureDetector(
                  onTap: isBusy ? null : _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (widget.profile.photoUrl != null
                                ? getImageProvider(widget.profile.photoUrl!)
                                : null),
                        child: (_selectedImage == null && widget.profile.photoUrl == null)
                            ? Text(
                                _initials(widget.profile.fullName),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isUploadingImage ? 'Processing image...' : 'Tap to change photo',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Editable fields ─────────────────────────────────────────
              AppTextField(
                controller: _fullNameController,
                label: 'Full Name',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── Read-only info ──────────────────────────────────────────
              _ReadOnlyInfo(
                label: 'Email',
                value: widget.profile.email,
                note: 'Contact support to change your email',
              ),
              const SizedBox(height: 12),
              _ReadOnlyInfo(
                label: 'Role',
                value: _roleLabel(widget.profile.role.name),
                note: 'Roles are managed by administrators',
              ),

              const SizedBox(height: 32),
              AppButton(
                text: 'Save Changes',
                isLoading: isBusy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    return name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
  }

  String _roleLabel(String role) => switch (role) {
        'SUPER_ADMIN' => 'Super Admin',
        'ADMIN' => 'Admin',
        'FINANCE_OFFICER' => 'Finance Officer',
        _ => 'Member',
      };
}

class _ReadOnlyInfo extends StatelessWidget {
  final String label;
  final String value;
  final String note;

  const _ReadOnlyInfo({
    required this.label,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16,
              color: AppColors.textSecondaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: $value',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
