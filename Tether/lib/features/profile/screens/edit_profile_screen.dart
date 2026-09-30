import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/media/image_crop.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_media.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/member_profile.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't load your profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(MemberProfile profile) {
    _nameCtrl.text = profile.displayName;
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
    final file = await cropPickedImage(picked, shape: ImageCropShape.avatar);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo must be smaller than 5 MB')),
      );
      return;
    }
    final mime = _mimeFor(file);
    if (mime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a JPEG, PNG, or WEBP image')),
      );
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
      backgroundColor: AppTheme.surfaceContainer,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Symbols.image),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickPhoto(source);
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
      await ref.read(profileServiceProvider).updateMyProfile(
            displayName: name,
            bodyWeightKg: _parseOptional(_weightCtrl.text),
            heightCm: _parseOptional(_heightCtrl.text),
            avatarPath: avatarPath,
            includeAvatar: avatarPath != null,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save your profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Edit profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.containerMargin,
                  8,
                  AppTheme.containerMargin,
                  32,
                ),
                children: [
                  Center(child: _avatar()),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _saving ? null : _choosePhoto,
                      child: const Text('Change photo'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.stackMd),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Symbols.person),
                    ),
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
                  const SizedBox(height: AppTheme.stackSm),
                  TextFormField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Body weight',
                      suffixText: 'kg',
                      prefixIcon: Icon(Symbols.monitor_weight),
                    ),
                    validator: (value) => _measureError(
                      value,
                      min: 20,
                      max: 400,
                      label: 'Body weight',
                    ),
                  ),
                  const SizedBox(height: AppTheme.stackSm),
                  TextFormField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      suffixText: 'cm',
                      prefixIcon: Icon(Symbols.height),
                    ),
                    validator: (value) => _measureError(
                      value,
                      min: 50,
                      max: 250,
                      label: 'Height',
                    ),
                  ),
                  const SizedBox(height: AppTheme.stackLg),
                  PrimaryButton(
                    label: 'Save',
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
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

  Widget _avatar() {
    const size = 96.0;
    Widget image;
    if (_pendingBytes != null) {
      image = Image.memory(_pendingBytes!, fit: BoxFit.cover, width: size, height: size);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      image = AppCachedImage(url: _avatarUrl, width: size, height: size);
    } else {
      image = const Icon(Symbols.person, size: 40, color: AppTheme.onSurfaceVariant);
    }

    return GestureDetector(
      onTap: _saving ? null : _choosePhoto,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceContainerHigh,
          border: Border.all(color: AppTheme.primaryContainer, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      ),
    );
  }
}
