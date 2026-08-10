import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../auth/models/user_model.dart';
import '../../../auth/services/auth_service.dart';

class _CountryCode {
  final String name;
  final String code;
  final String flag;

  const _CountryCode({
    required this.name,
    required this.code,
    required this.flag,
  });
}

const List<_CountryCode> _countryCodes = [
  _CountryCode(name: 'Philippines', code: '+63', flag: '🇵🇭'),
  _CountryCode(name: 'United States', code: '+1', flag: '🇺🇸'),
  _CountryCode(name: 'Singapore', code: '+65', flag: '🇸🇬'),
  _CountryCode(name: 'Australia', code: '+61', flag: '🇦🇺'),
  _CountryCode(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
  _CountryCode(name: 'Japan', code: '+81', flag: '🇯🇵'),
  _CountryCode(name: 'South Korea', code: '+82', flag: '🇰🇷'),
  _CountryCode(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪'),
  _CountryCode(name: 'Saudi Arabia', code: '+966', flag: '🇸🇦'),
  _CountryCode(name: 'India', code: '+91', flag: '🇮🇳'),
  _CountryCode(name: 'Malaysia', code: '+60', flag: '🇲🇾'),
  _CountryCode(name: 'Indonesia', code: '+62', flag: '🇮🇩'),
  _CountryCode(name: 'Thailand', code: '+66', flag: '🇹🇭'),
  _CountryCode(name: 'Vietnam', code: '+84', flag: '🇻🇳'),
  _CountryCode(name: 'New Zealand', code: '+64', flag: '🇳🇿'),
  _CountryCode(name: 'Germany', code: '+49', flag: '🇩🇪'),
  _CountryCode(name: 'France', code: '+33', flag: '🇫🇷'),
  _CountryCode(name: 'Spain', code: '+34', flag: '🇪🇸'),
  _CountryCode(name: 'Italy', code: '+39', flag: '🇮🇹'),
  _CountryCode(name: 'Brazil', code: '+55', flag: '🇧🇷'),
  _CountryCode(name: 'Mexico', code: '+52', flag: '🇲🇽'),
  _CountryCode(name: 'Hong Kong', code: '+852', flag: '🇭🇰'),
  _CountryCode(name: 'Taiwan', code: '+886', flag: '🇹🇼'),
];

/// Edit Profile Screen for updating user display name, phone number, location, bio, profile avatar, and cover photo
class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.isDarkMode,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;

  _CountryCode _selectedCountry = _countryCodes[0]; // Philippines +63 default

  Uint8List? _avatarBytes;
  String? _uploadedAvatarUrl;

  Uint8List? _coverBytes;
  String? _uploadedCoverUrl;

  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _locationController = TextEditingController(text: widget.user.location ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _uploadedAvatarUrl = widget.user.avatarUrl;
    _uploadedCoverUrl = widget.user.coverPhotoUrl;

    // Parse existing phone number to detect country code
    final rawPhone = (widget.user.phoneNumber ?? '').trim();
    if (rawPhone.isNotEmpty) {
      _CountryCode? matched;
      for (final country in _countryCodes) {
        if (rawPhone.startsWith(country.code)) {
          matched = country;
          break;
        }
      }
      if (matched != null) {
        _selectedCountry = matched;
        final digits = rawPhone.substring(matched.code.length).trim();
        _phoneController = TextEditingController(text: digits);
      } else {
        _phoneController = TextEditingController(text: rawPhone);
      }
    } else {
      _phoneController = TextEditingController(text: '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showCountryCodePicker() {
    final isDark = widget.isDarkMode;
    String filterQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PulseColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _countryCodes.where((c) {
              final q = filterQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              return c.name.toLowerCase().contains(q) || c.code.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PulseColors.getBorder(isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Country Dialing Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: PulseColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (val) => setModalState(() => filterQuery = val),
                    style: TextStyle(
                      fontSize: 14,
                      color: PulseColors.getTextPrimary(isDark),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search country or code (e.g. Philippines or +63)',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: PulseColors.getTextSecondary(isDark),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: PulseColors.getBorder(isDark).withValues(alpha: 0.3),
                      ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.code == _selectedCountry.code;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Text(
                            item.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: PulseColors.getTextPrimary(isDark),
                            ),
                          ),
                          trailing: Text(
                            item.code,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? PulseColors.accent : PulseColors.getTextSecondary(isDark),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCountry = item;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAvatarImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _isUploadingAvatar = true;
      });

      final avatarUrl = await _authService.uploadAvatarImage(
        bytes,
        mimeType: image.mimeType ?? 'image/jpeg',
      );

      if (mounted) {
        setState(() {
          _uploadedAvatarUrl = avatarUrl;
          _isUploadingAvatar = false;
        });
        PulseToast.showSuccess(context, 'Avatar photo uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        PulseToast.showError(
          context,
          'Upload failed: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    }
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _coverBytes = bytes;
        _isUploadingCover = true;
      });

      final coverUrl = await _authService.uploadAvatarImage(
        bytes,
        mimeType: image.mimeType ?? 'image/jpeg',
      );

      if (mounted) {
        setState(() {
          _uploadedCoverUrl = coverUrl;
          _isUploadingCover = false;
        });
        PulseToast.showSuccess(context, 'Cover photo uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
        PulseToast.showError(
          context,
          'Cover upload failed: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    }
  }

  void _showImageSourcePicker({required bool isCover}) {
    final isDark = widget.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: PulseColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCover ? 'Change Cover Photo' : 'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: PulseColors.primary),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: PulseColors.getTextPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isCover) {
                    _pickCoverImage(ImageSource.gallery);
                  } else {
                    _pickAvatarImage(ImageSource.gallery);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: PulseColors.accent),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: PulseColors.getTextPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isCover) {
                    _pickCoverImage(ImageSource.camera);
                  } else {
                    _pickAvatarImage(ImageSource.camera);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final phoneDigits = _phoneController.text.trim();
    final newPhone = phoneDigits.isNotEmpty ? '${_selectedCountry.code} $phoneDigits' : '';
    final newLocation = _locationController.text.trim();
    final newBio = _bioController.text.trim();

    final hasNameChange = newName != widget.user.name;
    final hasAvatarChange = _uploadedAvatarUrl != widget.user.avatarUrl;
    final hasCoverChange = _uploadedCoverUrl != widget.user.coverPhotoUrl;
    final hasPhoneChange = newPhone != (widget.user.phoneNumber ?? '');
    final hasLocationChange = newLocation != (widget.user.location ?? '');
    final hasBioChange = newBio != (widget.user.bio ?? '');

    if (!hasNameChange && !hasAvatarChange && !hasCoverChange && !hasPhoneChange && !hasLocationChange && !hasBioChange) {
      PulseToast.showInfo(context, 'No profile changes to save');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedUser = await _authService.updateProfile(
        name: newName,
        avatarUrl: _uploadedAvatarUrl,
        coverPhotoUrl: _uploadedCoverUrl,
        phoneNumber: newPhone,
        location: newLocation,
        bio: newBio,
      );

      if (mounted) {
        PulseToast.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        PulseToast.showError(
          context,
          'Failed to update profile: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final initials = widget.user.name.isNotEmpty
        ? widget.user.name[0].toUpperCase()
        : 'P';

    return Scaffold(
      backgroundColor: PulseColors.getBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Flat Header with Circular Back Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: PulseColors.getSurface(isDark),
                border: Border(
                  bottom: BorderSide(
                    color: PulseColors.getBorder(isDark),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  PulseBackButton(isDarkMode: isDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: PulseColors.getTextPrimary(isDark),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Update details, avatar & cover photo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: PulseColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form & Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Cover Banner & Overlapping Avatar Header
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Cover Photo Banner Image Container
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? PulseColors.darkCard : PulseColors.secondary.withValues(alpha: 0.3),
                                gradient: (_coverBytes == null && (_uploadedCoverUrl == null || _uploadedCoverUrl!.isEmpty))
                                    ? LinearGradient(
                                        colors: isDark
                                            ? [const Color(0xFF1B3B36), const Color(0xFF0F2622)]
                                            : [PulseColors.primary, const Color(0xFF2C5E55)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_coverBytes != null)
                                    Image.memory(_coverBytes!, fit: BoxFit.cover)
                                  else if (_uploadedCoverUrl != null && _uploadedCoverUrl!.isNotEmpty)
                                    Image.network(
                                      _uploadedCoverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Center(
                                        child: Icon(
                                          Icons.sports_tennis_rounded,
                                          size: 80,
                                          color: Colors.white.withValues(alpha: 0.15),
                                        ),
                                      ),
                                    )
                                  else
                                    Positioned(
                                      right: -10,
                                      top: -10,
                                      child: Icon(
                                        Icons.sports_tennis_rounded,
                                        size: 160,
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),

                                  if (_isUploadingCover)
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),

                                  // Change Cover Photo Button (Top Right of Banner)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: InkWell(
                                      onTap: (_isSaving || _isUploadingCover)
                                          ? null
                                          : () => _showImageSourcePicker(isCover: true),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.camera_alt_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Cover Photo',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Overlapping Centered Avatar Photo (50% on Banner, 50% on Body)
                            Positioned(
                              top: 86,
                              child: SizedBox(
                                width: 112,
                                height: 112,
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: PulseColors.getBackground(isDark),
                                          border: Border.all(
                                            color: PulseColors.getBackground(isDark),
                                            width: 3.5,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: _avatarBytes != null
                                              ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                                              : (_uploadedAvatarUrl != null && _uploadedAvatarUrl!.isNotEmpty)
                                                  ? Image.network(
                                                      _uploadedAvatarUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Center(
                                                        child: Text(
                                                          initials,
                                                          style: TextStyle(
                                                            fontSize: 36,
                                                            fontWeight: FontWeight.w900,
                                                            color: PulseColors.getTextPrimary(isDark),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        initials,
                                                        style: TextStyle(
                                                          fontSize: 36,
                                                          fontWeight: FontWeight.w900,
                                                          color: PulseColors.getTextPrimary(isDark),
                                                        ),
                                                      ),
                                                    ),
                                        ),
                                      ),
                                    ),
                                    if (_isUploadingAvatar)
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withValues(alpha: 0.5),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: (_isSaving || _isUploadingAvatar)
                                            ? null
                                            : () => _showImageSourcePicker(isCover: false),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: PulseColors.accent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.0,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Rest of Form Content uses Padded Body Area
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Input Fields Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: PulseColors.getSurface(isDark),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: PulseColors.getBorder(isDark),
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FULL NAME',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: PulseColors.getTextSecondary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PulseColors.getTextPrimary(isDark),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your full name',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                        size: 20,
                                        color: PulseColors.getTextSecondary(isDark),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Full name cannot be empty';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'PHONE NUMBER',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: PulseColors.getTextSecondary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: _showCountryCodePicker,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 52,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: PulseColors.getSurface(isDark),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: PulseColors.getBorder(isDark),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _selectedCountry.flag,
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _selectedCountry.code,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: PulseColors.getTextPrimary(isDark),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_drop_down_rounded,
                                                color: PulseColors.getTextSecondary(isDark),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: PulseColors.getTextPrimary(isDark),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _selectedCountry.code == '+63' ? '917 123 4567' : 'Subscriber number',
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'HOME COURT / LOCATION',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: PulseColors.getTextSecondary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _locationController,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PulseColors.getTextPrimary(isDark),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Manila Tennis Club, Court 4',
                                      prefixIcon: Icon(
                                        Icons.location_on_outlined,
                                        size: 20,
                                        color: PulseColors.getTextSecondary(isDark),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'PLAYER BIO / TAGLINE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: PulseColors.getTextSecondary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PulseColors.getTextPrimary(isDark),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Left-handed player, available weekday evenings...',
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.only(bottom: 38.0),
                                        child: Icon(
                                          Icons.notes_rounded,
                                          size: 20,
                                          color: PulseColors.getTextSecondary(isDark),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'REGISTERED EMAIL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: PulseColors.getTextSecondary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: widget.user.email,
                                    readOnly: true,
                                    enabled: false,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PulseColors.getTextSecondary(isDark),
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        size: 20,
                                        color: PulseColors.getTextSecondary(isDark),
                                      ),
                                      suffixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18,
                                        color: PulseColors.getTextSecondary(isDark),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Save Button
                            ElevatedButton(
                              onPressed: (_isSaving || _isUploadingAvatar || _isUploadingCover) ? null : _handleSaveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PulseColors.primary,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Save Profile Changes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),

                          ],
                        ),
                      ),
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
}
