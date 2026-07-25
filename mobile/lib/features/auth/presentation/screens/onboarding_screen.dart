import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/rally_text_logo.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  final UserModel user;

  const OnboardingScreen({super.key, required this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  int _currentStep = 0;
  bool _isLoading = false;

  // Avatar upload state
  Uint8List? _avatarBytes;
  String? _uploadedAvatarUrl;
  bool _isUploadingAvatar = false;
  final ImagePicker _picker = ImagePicker();

  // Step 2 selections
  String _selectedSport = 'Pickleball';
  int _selectedRating = 1200; // Default Intermediate

  final List<Map<String, dynamic>> _sports = [
    {'name': 'Pickleball', 'icon': Icons.sports_tennis_rounded},
    {'name': 'Tennis', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Table Tennis', 'icon': Icons.sports_score_rounded},
    {'name': 'Badminton', 'icon': Icons.sports_handball_rounded},
  ];

  final List<Map<String, dynamic>> _ratings = [
    {'label': 'Beginner', 'rating': 1000, 'color': const Color(0xFF4CAF50), 'desc': 'New to competitive play'},
    {'label': 'Intermediate', 'rating': 1200, 'color': const Color(0xFF2196F3), 'desc': 'Played social/club games'},
    {'label': 'Advanced', 'rating': 1400, 'color': const Color(0xFFFF9800), 'desc': 'Experienced tournament player'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
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

      // Upload directly to Cloudflare R2 via presigned URL
      final avatarUrl = await _authService.uploadAvatarImage(
        bytes,
        mimeType: image.mimeType ?? 'image/jpeg',
      );

      if (mounted) {
        setState(() {
          _uploadedAvatarUrl = avatarUrl;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar uploaded successfully!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar upload failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: PulseColors.error,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: PulseColors.getSurface(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload Profile Avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? PulseColors.darkTextPrimary : PulseColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: PulseColors.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAvatarImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: PulseColors.secondary),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAvatarImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleFinish() async {
    setState(() => _isLoading = true);
    try {
      final updatedUser = await _authService.completeOnboarding(
        primarySport: _selectedSport,
        rating: _selectedRating,
        avatarUrl: _uploadedAvatarUrl,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(user: updatedUser),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: PulseColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = PulseColors.getTextPrimary(isDark);
    final textSecondary = PulseColors.getTextSecondary(isDark);

    return Scaffold(
      backgroundColor: PulseColors.getBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Center(
              child: RallyTextLogo(fontSize: 28, showSubtitle: false),
            ),
            const SizedBox(height: 16),

            // Step Indicator Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? PulseColors.accent : (isDark ? PulseColors.darkBorder : PulseColors.border),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Step ${_currentStep + 1} of 3',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Page View Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildStep1(isDark, textPrimary, textSecondary),
                  _buildStep2(isDark, textPrimary, textSecondary),
                  _buildStep3(isDark, textPrimary, textSecondary),
                ],
              ),
            ),

            // Navigation Buttons Bottom Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('BACK'),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  if (_currentStep < 2)
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('NEXT'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleFinish,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        backgroundColor: PulseColors.accent,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('GET STARTED'),
                                SizedBox(width: 6),
                                Icon(Icons.check_circle_outline_rounded, size: 18),
                              ],
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Player Profile & Handle Confirmation
  Widget _buildStep1(bool isDark, Color textPrimary, Color textSecondary) {
    final nameInitial = widget.user.firstName.isNotEmpty ? widget.user.firstName[0].toUpperCase() : 'P';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: PulseColors.primary,
                        backgroundImage: _avatarBytes != null
                            ? MemoryImage(_avatarBytes!)
                            : (_uploadedAvatarUrl != null
                                ? NetworkImage(_uploadedAvatarUrl!) as ImageProvider
                                : (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                                    ? NetworkImage(widget.user.avatarUrl!)
                                    : null)),
                        child: (_avatarBytes == null && _uploadedAvatarUrl == null && (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty))
                            ? Text(
                                nameInitial,
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            : null,
                      ),
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: PulseColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: PulseColors.getSurface(isDark), width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to Rally!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirm your player handle for competitive rankings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Player Display Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    fillColor: PulseColors.getSurface(isDark),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // STEP 2: Sport & Initial Rating Tier
  Widget _buildStep2(bool isDark, Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Primary Sport',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your main sport for verified matches.',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 16),

          // Sport Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _sports.length,
            itemBuilder: (context, index) {
              final sport = _sports[index];
              final isSelected = _selectedSport == sport['name'];
              return InkWell(
                onTap: () => setState(() => _selectedSport = sport['name'] as String),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PulseColors.accent.withValues(alpha: 0.15)
                        : PulseColors.getSurface(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? PulseColors.accent : (isDark ? PulseColors.darkBorder : PulseColors.border),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sport['icon'] as IconData,
                        color: isSelected ? PulseColors.accent : textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sport['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? PulseColors.accent : textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          Text(
            'Select Skill Level',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Sets your starting Elo rating for rankings.',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 12),

          // Rating Tiers List
          Column(
            children: _ratings.map((tier) {
              final isSelected = _selectedRating == tier['rating'];
              final color = tier['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => setState(() => _selectedRating = tier['rating'] as int),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.12)
                          : PulseColors.getSurface(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : (isDark ? PulseColors.darkBorder : PulseColors.border),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tier['label']} (${tier['rating']} ELO)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tier['desc'] as String,
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: color, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // STEP 3: Ready to Rally! Minimalist Competitor Pass Card
  Widget _buildStep3(bool isDark, Color textPrimary, Color textSecondary) {
    final displayName = _nameController.text.isNotEmpty ? _nameController.text : widget.user.name;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minimalist Competitor Pass Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: PulseColors.getSurface(isDark),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? PulseColors.darkBorder : PulseColors.border.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Success pill tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'COMPETITOR PROFILE READY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4CAF50),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Avatar preview with accent ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: PulseColors.accent, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: PulseColors.primary,
                          backgroundImage: _avatarBytes != null
                              ? MemoryImage(_avatarBytes!)
                              : (_uploadedAvatarUrl != null
                                  ? NetworkImage(_uploadedAvatarUrl!) as ImageProvider
                                  : (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                                      ? NetworkImage(widget.user.avatarUrl!)
                                      : null)),
                          child: (_avatarBytes == null && _uploadedAvatarUrl == null && (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty))
                              ? Text(
                                  initial,
                                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Minimalist Sport & Rating Badges
                      Row(
                        children: [
                          Expanded(
                            child: _buildMinimalBadge(
                              label: 'PRIMARY SPORT',
                              value: _selectedSport,
                              icon: Icons.sports_tennis_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMinimalBadge(
                              label: 'STARTING ELO',
                              value: '$_selectedRating ELO',
                              icon: Icons.emoji_events_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'You are all set to join or score verified matches!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalBadge({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E292B) : const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: PulseColors.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: PulseColors.getTextSecondary(isDark),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PulseColors.getTextPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
