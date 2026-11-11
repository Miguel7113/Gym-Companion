import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/media/image_crop.dart';
import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/cached_media.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/member_profile.dart';
import '../services/profile_service.dart';

/// Redesigned Edit Profile screen matching the new Tether aesthetic
/// Dark ink header + cream content sheet
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _avatarUrl;
  Uint8List? _pendingBytes;
  String? _pendingMime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final memberId = ref.read(currentUserProvider)?.memberId;
    if (memberId == null || memberId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profile =
          await ref.read(profileServiceProvider).getMemberProfile(memberId);
      if (!mounted) return;
      _apply(profile);
    } catch (e) {
      if (!mounted) return;
      _showError("Couldn't load your profile: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(MemberProfile profile) {
    _nameCtrl.text = profile.displayName;
    _bioCtrl.text = profile.bio ?? '';
    _weightCtrl.text = _formatMeasure(profile.bodyWeightKg);
    _heightCtrl.text = _formatMeasure(profile.heightCm);
    _avatarUrl = profile.avatarUrl;
  }

  String _formatMeasure(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;
    if (!mounted) return;
    final file = await cropPickedImage(
      picked,
      shape: ImageCropShape.avatar,
      context: context,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      _showError('Photo must be smaller than 5 MB');
      return;
    }
    final mime = _mimeFor(file);
    if (mime == null) {
      if (!mounted) return;
      _showError('Choose a JPEG, PNG, or WEBP image');
      return;
    }
    setState(() {
      _pendingBytes = bytes;
      _pendingMime = mime;
    });
  }

  String? _mimeFor(XFile file) {
    final mime = file.mimeType;
    if (const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
      return mime;
    }
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFFE4DFD3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TetherTokens.ink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildPhotoOption(
              'Take a photo',
              Symbols.photo_camera,
              () => Navigator.pop(context, ImageSource.camera),
            ),
            _buildPhotoOption(
              'Choose from library',
              Symbols.image,
              () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickPhoto(source);
  }

  Widget _buildPhotoOption(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: TetherTokens.cream,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: TetherTokens.ink),
            const SizedBox(width: 12),
            Text(
              label,
              style: TetherText.sans(
                15,
                color: TetherTokens.ink,
                w: TetherTokens.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _parseOptional(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<String?> _uploadAvatar() async {
    final bytes = _pendingBytes;
    final mime = _pendingMime;
    if (bytes == null || mime == null) return null;
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      throw StateError('You must be signed in to update your photo');
    }
    final extension = mime == 'image/png'
        ? 'png'
        : mime == 'image/webp'
            ? 'webp'
            : 'jpg';
    final path = '${authUser.id}/avatar.$extension';
    await Supabase.instance.client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: true),
        );
    return path;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final avatarPath = await _uploadAvatar();
      final name = _nameCtrl.text.trim();
      final bio = _bioCtrl.text.trim();
      
      await ref.read(profileServiceProvider).updateMyProfile(
            displayName: name,
            bio: bio.isEmpty ? null : bio,
            bodyWeightKg: _parseOptional(_weightCtrl.text),
            heightCm: _parseOptional(_heightCtrl.text),
            avatarPath: avatarPath,
            includeAvatar: avatarPath != null,
            includeBio: true,
          );
      
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'display_name': name}),
        );
      } catch (e) {
        debugPrint('[EditProfile] display name metadata update failed: $e');
      }
      
      final memberId = ref.read(currentUserProvider)?.memberId;
      if (memberId != null && memberId.isNotEmpty) {
        ref.invalidate(memberProfileProvider(memberId));
      }
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError("Couldn't save your profile: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TetherTokens.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: TetherTokens.defaultAccent,
                ),
              )
            : Column(
                children: [
                  // Dark header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: TetherTokens.nightCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: TetherTokens.cream.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: TetherTokens.cream,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'EDIT PROFILE',
                            style: TetherText.sans(
                              20,
                              color: TetherTokens.cream,
                              w: TetherTokens.w800,
                              ls: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cream content sheet
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: TetherTokens.cream,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                          children: [
                            // Avatar with edit button
                            Center(child: _buildAvatar()),
                            const SizedBox(height: 12),
                            Center(
                              child: GestureDetector(
                                onTap: _saving ? null : _choosePhoto,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4DFD3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Symbols.photo_camera,
                                        size: 16,
                                        color: p.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'CHANGE PHOTO',
                                        style: TetherText.sans(
                                          12,
                                          color: p.accent,
                                          w: TetherTokens.w600,
                                          ls: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Name field
                            _buildLabel('NAME'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameCtrl,
                              hint: 'Enter your name',
                              icon: Symbols.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your name';
                                }
                                if (value.trim().length > 120) {
                                  return 'Name is too long';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Bio field
                            _buildLabel('BIO (OPTIONAL)'),
                            const SizedBox(height: 8),
                            _buildTextArea(
                              controller: _bioCtrl,
                              hint: 'Tell us about yourself...',
                              maxLength: 200,
                            ),

                            const SizedBox(height: 24),

                            // Body weight field
                            _buildLabel('BODY WEIGHT (OPTIONAL)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _weightCtrl,
                              hint: 'Enter weight',
                              icon: Symbols.monitor_weight,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              suffixText: 'kg',
                              validator: (value) => _measureError(
                                value,
                                min: 20,
                                max: 400,
                                label: 'Body weight',
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Height field
                            _buildLabel('HEIGHT (OPTIONAL)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _heightCtrl,
                              hint: 'Enter height',
                              icon: Symbols.height,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              suffixText: 'cm',
                              validator: (value) => _measureError(
                                value,
                                min: 50,
                                max: 250,
                                label: 'Height',
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Save button
                            _buildSaveButton(),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TetherText.sans(
        10,
        color: TetherTokens.ink.withOpacity(0.5),
        w: TetherTokens.w600,
        ls: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final p = context.tether;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TetherText.sans(
        15,
        color: TetherTokens.ink,
        w: TetherTokens.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TetherText.sans(
          15,
          color: TetherTokens.ink.withOpacity(0.3),
          w: TetherTokens.w400,
        ),
        prefixIcon: Icon(icon, size: 20, color: TetherTokens.ink.withOpacity(0.4)),
        suffixText: suffixText,
        suffixStyle: TetherText.sans(
          14,
          color: TetherTokens.ink.withOpacity(0.5),
          w: TetherTokens.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFE4DFD3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
  }) {
    final p = context.tether;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: 4,
          maxLength: maxLength,
          style: TetherText.sans(
            14,
            color: TetherTokens.ink,
            w: TetherTokens.w400,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TetherText.sans(
              14,
              color: TetherTokens.ink.withOpacity(0.3),
              w: TetherTokens.w400,
              height: 1.5,
            ),
            filled: true,
            fillColor: const Color(0xFFE4DFD3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: p.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Text(
          '${_bioCtrl.text.length}/$maxLength',
          style: TetherText.sans(
            11,
            color: TetherTokens.ink.withOpacity(0.4),
            w: TetherTokens.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final p = context.tether;
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _saving ? TetherTokens.ink.withOpacity(0.3) : TetherTokens.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      TetherTokens.cream,
                    ),
                  ),
                )
              : Text(
                  'SAVE CHANGES',
                  style: TetherText.sans(
                    14,
                    color: TetherTokens.cream,
                    w: TetherTokens.w800,
                    ls: 0.8,
                  ),
                ),
        ),
      ),
    );
  }

  String? _measureError(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < min || parsed > max) {
      return '$label must be between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)}';
    }
    return null;
  }

  Widget _buildAvatar() {
    const size = 100.0;
    final p = context.tether;
    
    Widget image;
    if (_pendingBytes != null) {
      image = Image.memory(
        _pendingBytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      image = AppCachedImage(
        url: _avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallback: _buildAvatarPlaceholder(),
      );
    } else {
      image = _buildAvatarPlaceholder();
    }

    return GestureDetector(
      onTap: _saving ? null : _choosePhoto,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.accent, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFE4DFD3),
      child: Center(
        child: Icon(
          Symbols.person,
          size: 40,
          color: TetherTokens.ink.withOpacity(0.3),
        ),
      ),
    );
  }
}
