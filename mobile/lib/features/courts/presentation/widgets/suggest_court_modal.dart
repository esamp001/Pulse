import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../models/court_model.dart';
import '../../services/court_service.dart';
import 'court_map_picker_modal.dart';

/// Modal bottom sheet allowing players to suggest or register a new court location.
class SuggestCourtModal extends StatefulWidget {
  final LatLng initialLocation;
  final String? initialAddress;
  final String? initialCity;
  final bool isDarkMode;
  final ValueChanged<CourtModel>? onCourtCreated;

  const SuggestCourtModal({
    super.key,
    required this.initialLocation,
    this.initialAddress,
    this.initialCity,
    required this.isDarkMode,
    this.onCourtCreated,
  });

  /// Opens the SuggestCourtModal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required bool isDarkMode,
    LatLng? initialLocation,
    String? initialAddress,
    String? initialCity,
    ValueChanged<CourtModel>? onCourtCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SuggestCourtModal(
        initialLocation: initialLocation ?? const LatLng(14.5995, 120.9842),
        initialAddress: initialAddress,
        initialCity: initialCity,
        isDarkMode: isDarkMode,
        onCourtCreated: onCourtCreated,
      ),
    );
  }

  @override
  State<SuggestCourtModal> createState() => _SuggestCourtModalState();
}

class _SuggestCourtModalState extends State<SuggestCourtModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CourtService _courtService = CourtService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late LatLng _currentLocation;

  final Set<String> _selectedSports = {'Pickleball'};
  String _selectedSurface = 'Hard Court';
  String _accessType = 'Public';
  bool _isIndoor = false;
  bool _hasLighting = false;
  bool _isSubmitting = false;

  Uint8List? _selectedPhotoBytes;

  static const List<String> _availableSports = [
    'Pickleball',
    'Tennis',
    'Badminton',
    'Table Tennis',
  ];

  static const List<String> _availableSurfaces = [
    'Hard Court',
    'Synthetic',
    'Clay',
    'Grass',
    'Wood',
    'Concrete',
  ];

  static const List<String> _accessTypes = [
    'Public',
    'Private',
    'Club',
  ];

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _nameController = TextEditingController();
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _cityController = TextEditingController(text: widget.initialCity ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await showModalBottomSheet<CourtMapPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CourtMapPickerModal(
        initialLocation: _currentLocation,
        initialAddress: _addressController.text.trim(),
        initialCity: _cityController.text.trim(),
        sport: _selectedSports.isNotEmpty ? _selectedSports.first : 'Tennis',
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _currentLocation = picked.location;
        if (picked.address.isNotEmpty) {
          _addressController.text = picked.address;
        }
        if (picked.city.isNotEmpty) {
          _cityController.text = picked.city;
        }
      });

      // If address was not resolved in the picker modal, fetch and update it here
      if (picked.address.isEmpty) {
        final geocoded = await _courtService.reverseGeocode(
          picked.location.latitude,
          picked.location.longitude,
        );
        if (mounted) {
          if (geocoded['address'] != null && geocoded['address']!.isNotEmpty) {
            setState(() {
              _addressController.text = geocoded['address']!;
              if (geocoded['city'] != null && geocoded['city']!.isNotEmpty) {
                _cityController.text = geocoded['city']!;
              }
            });
          }
        }
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedPhotoBytes = bytes;
        });
      }
    } catch (err) {
      debugPrint('[SuggestCourtModal photo picker error]: $err');
      if (mounted) {
        PulseToast.show(context, 'Could not select photo');
      }
    }
  }

  void _showPhotoSourceSheet() {
    final isDark = widget.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: PulseColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Court Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: isDark ? Colors.white : PulseColors.primary,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: PulseColors.getTextPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: isDark ? Colors.white : PulseColors.primary,
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: PulseColors.getTextPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSports.isEmpty) {
      PulseToast.show(context, 'Please select at least one sport');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoUrl;
      if (_selectedPhotoBytes != null) {
        photoUrl = await _courtService.uploadCourtPhoto(
          _selectedPhotoBytes!,
          mimeType: 'image/jpeg',
        );
      }

      final court = await _courtService.suggestCourt(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        sports: _selectedSports.map((s) => s.toLowerCase()).toList(),
        surface: _selectedSurface.toLowerCase(),
        hasLighting: _hasLighting,
        isIndoor: _isIndoor,
        accessType: _accessType.toLowerCase(),
        imageUrl: photoUrl,
      );

      if (mounted) {
        if (court != null) {
          Navigator.of(context).pop();
          widget.onCourtCreated?.call(court);
        } else {
          PulseToast.show(context, 'Failed to suggest court. Please try again.');
        }
      }
    } catch (err) {
      debugPrint('[SuggestCourtModal Submit Error]: $err');
      if (mounted) {
        PulseToast.show(context, 'An error occurred while submitting.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: PulseColors.getBackground(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle & Header
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : PulseColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_location_alt_rounded,
                        color: isDark ? Colors.white : PulseColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggest a Court',
                            style: TextStyle(
                              color: PulseColors.getTextPrimary(isDark),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Help players discover this venue',
                            style: TextStyle(
                              color: PulseColors.getTextSecondary(isDark),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: isDark ? Colors.white : PulseColors.getTextSecondary(isDark),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.5),

              // 2. Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Court Name
                        _buildSectionLabel('Court Name *', isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(
                            color: PulseColors.getTextPrimary(isDark),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., Central Park Courts',
                            hintStyle: TextStyle(
                              color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: PulseColors.getCard(isDark),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            prefixIcon: Icon(
                              Icons.sports_tennis_rounded,
                              size: 18,
                              color: isDark ? Colors.white : PulseColors.primary,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter the court name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Location Coordinates Card
                        _buildSectionLabel('Pinned Location', isDark),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: PulseColors.getCard(isDark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                size: 20,
                                color: isDark ? Colors.white : PulseColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_currentLocation.latitude.toStringAsFixed(5)}, ${_currentLocation.longitude.toStringAsFixed(5)}',
                                      style: TextStyle(
                                        color: PulseColors.getTextPrimary(isDark),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap "Change on Map" to adjust pin',
                                      style: TextStyle(
                                        color: PulseColors.getTextSecondary(isDark),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _pickLocationOnMap,
                                icon: Icon(
                                  Icons.map_outlined,
                                  size: 16,
                                  color: isDark ? Colors.white : PulseColors.primary,
                                ),
                                label: Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : PulseColors.primary,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : PulseColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Street Address
                        _buildSectionLabel('Street Address (Optional)', isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          style: TextStyle(
                            color: PulseColors.getTextPrimary(isDark),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., 7th Ave & 28th St',
                            hintStyle: TextStyle(
                              color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: PulseColors.getCard(isDark),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: isDark ? Colors.white : PulseColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // City
                        _buildSectionLabel('City (Optional)', isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cityController,
                          style: TextStyle(
                            color: PulseColors.getTextPrimary(isDark),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., Taguig, Metro Manila',
                            hintStyle: TextStyle(
                              color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: PulseColors.getCard(isDark),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            prefixIcon: Icon(
                              Icons.location_city_rounded,
                              size: 18,
                              color: isDark ? Colors.white : PulseColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Sports Available
                        _buildSectionLabel('Sports Available', isDark),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSports.map((sport) {
                            final isSelected = _selectedSports.contains(sport);
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    if (_selectedSports.length > 1) {
                                      _selectedSports.remove(sport);
                                    } else {
                                      PulseToast.show(context, 'At least one sport is required');
                                    }
                                  } else {
                                    _selectedSports.add(sport);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? PulseColors.primary : PulseColors.getCard(isDark),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PulseSportIcons.buildWidget(
                                      sport,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white : PulseColors.getTextSecondary(isDark)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      sport,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : PulseColors.getTextPrimary(isDark),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Surface Type
                        _buildSectionLabel('Surface Type', isDark),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSurfaces.map((surface) {
                            final isSelected = _selectedSurface == surface;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() => _selectedSurface = surface),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? PulseColors.primary : PulseColors.getCard(isDark),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  surface,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : PulseColors.getTextPrimary(isDark),
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Access Type
                        _buildSectionLabel('Access Type', isDark),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _accessTypes.map((type) {
                            final isSelected = _accessType == type;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() => _accessType = type),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? PulseColors.primary : PulseColors.getCard(isDark),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : PulseColors.getTextPrimary(isDark),
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Features & Amenities Toggles
                        _buildSectionLabel('Amenities', isDark),
                        const SizedBox(height: 8),
                        Material(
                          color: PulseColors.getCard(isDark),
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SwitchListTile.adaptive(
                                value: _hasLighting,
                                onChanged: (val) => setState(() => _hasLighting = val),
                                title: Text(
                                  'Night Lighting',
                                  style: TextStyle(
                                    color: PulseColors.getTextPrimary(isDark),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Available for evening play',
                                  style: TextStyle(
                                    color: PulseColors.getTextSecondary(isDark),
                                    fontSize: 11,
                                  ),
                                ),
                                secondary: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: isDark ? Colors.white : PulseColors.primary,
                                  size: 20,
                                ),
                                thumbColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? Colors.white
                                      : PulseColors.primary,
                                ),
                                activeTrackColor: PulseColors.primary,
                                overlayColor: WidgetStateProperty.all(Colors.transparent),
                                dense: true,
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              SwitchListTile.adaptive(
                                value: _isIndoor,
                                onChanged: (val) => setState(() => _isIndoor = val),
                                title: Text(
                                  'Indoor Venue',
                                  style: TextStyle(
                                    color: PulseColors.getTextPrimary(isDark),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Weatherproof enclosed facility',
                                  style: TextStyle(
                                    color: PulseColors.getTextSecondary(isDark),
                                    fontSize: 11,
                                  ),
                                ),
                                secondary: Icon(
                                  Icons.roofing_rounded,
                                  color: isDark ? Colors.white : PulseColors.primary,
                                  size: 20,
                                ),
                                thumbColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? Colors.white
                                      : PulseColors.primary,
                                ),
                                activeTrackColor: PulseColors.primary,
                                overlayColor: WidgetStateProperty.all(Colors.transparent),
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Court Photo (Optional)
                        _buildSectionLabel('Court Photo (Optional)', isDark),
                        const SizedBox(height: 8),
                        if (_selectedPhotoBytes != null)
                          Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: PulseColors.getCard(isDark),
                                  image: DecorationImage(
                                    image: MemoryImage(_selectedPhotoBytes!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedPhotoBytes = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _showPhotoSourceSheet,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: PulseColors.getCard(isDark),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 26,
                                    color: isDark ? Colors.white : PulseColors.primary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add photo of the court',
                                    style: TextStyle(
                                      color: PulseColors.getTextSecondary(isDark),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Bottom Action Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.getBackground(isDark),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'Registering Venue...' : 'Register Court',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        color: PulseColors.getTextSecondary(isDark),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
