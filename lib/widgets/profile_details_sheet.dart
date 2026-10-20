import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/app_store.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'app_image.dart';

/// Interactive modal sheet displaying user details and allowing profile picture updates.
void showProfileDetailsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ProfileDetailsSheet(),
  );
}

class ProfileDetailsSheet extends StatefulWidget {
  const ProfileDetailsSheet({super.key});

  @override
  State<ProfileDetailsSheet> createState() => _ProfileDetailsSheetState();
}

class _ProfileDetailsSheetState extends State<ProfileDetailsSheet> {
  bool _isEditing = false;
  bool _isUploading = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400',
    'assets/images/avatar.jpg',
  ];

  @override
  void initState() {
    super.initState();
    final user = AppStore.instance.currentUser;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _locationController = TextEditingController(text: user.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    Navigator.pop(context); // close photo picker sheet
    setState(() => _isUploading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final uploadedUrl = await ApiService.instance.uploadImage(
          bytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        final targetAvatar = uploadedUrl ?? file.path;
        await AppStore.instance.updateProfile(avatarUrl: targetAvatar);

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully! 🎉'),
            backgroundColor: Color(0xFF005C42),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to pick photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _selectPresetAvatar(String url) async {
    Navigator.pop(context); // close photo picker sheet
    setState(() => _isUploading = true);
    await AppStore.instance.updateProfile(avatarUrl: url);
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile avatar updated! 🎉'),
          backgroundColor: Color(0xFF005C42),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showChangePhotoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2DFD8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change Profile Picture',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a photo from your device or pick a styled avatar.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // Camera & Gallery action buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickAndUploadPhoto(ImageSource.camera),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7E2D3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            'Take Photo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickAndUploadPhoto(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7E2D3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            'Gallery',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),

            Text(
              'Or Choose Preset Avatar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presetAvatars.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final preset = _presetAvatars[i];
                  return GestureDetector(
                    onTap: () => _selectPresetAvatar(preset),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC7E2D3), width: 2),
                      ),
                      child: ClipOval(
                        child: AppImageWidget(pathOrUrl: preset, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isUploading = true);
    await AppStore.instance.updateProfile(
      name: name,
      phone: phone,
      location: location,
    );
    if (mounted) {
      setState(() {
        _isUploading = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details saved successfully!'),
          backgroundColor: Color(0xFF005C42),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final user = AppStore.instance.currentUser;
        final joinedText = DateFormat('MMM yyyy').format(user.joinedDate);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top drag handle
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2DFD8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),

                // Title row with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF557064)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Profile Avatar with Camera Overlay
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isUploading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              )
                            : AppImageWidget(
                                pathOrUrl: user.avatarUrl,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showChangePhotoModal,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                const SizedBox(height: 10),

                // "Tap to change photo" button
                TextButton.icon(
                  onPressed: _showChangePhotoModal,
                  icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                  label: Text(
                    'Change Profile Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Name & Verified Badge
                Text(
                  user.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 13, color: Color(0xFF065F46)),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Member • Mumbai Hub',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Details Card / Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FAF7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2EBE5)),
                  ),
                  child: Column(
                    children: [
                      if (!_isEditing) ...[
                        _buildDetailRow(Icons.email_outlined, 'Email', user.email),
                        const Divider(height: 18, color: Color(0xFFE2EBE5)),
                        _buildDetailRow(Icons.phone_outlined, 'Mobile', user.phone.isNotEmpty ? user.phone : 'Not provided'),
                        const Divider(height: 18, color: Color(0xFFE2EBE5)),
                        _buildDetailRow(Icons.location_on_outlined, 'Location', user.location),
                        const Divider(height: 18, color: Color(0xFFE2EBE5)),
                        _buildDetailRow(Icons.badge_outlined, 'User ID', user.id),
                        const Divider(height: 18, color: Color(0xFFE2EBE5)),
                        _buildDetailRow(Icons.calendar_today_outlined, 'Member Since', joinedText),
                      ] else ...[
                        _buildInputField('Full Name', _nameController, Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildInputField('Mobile Number', _phoneController, Icons.phone_outlined),
                        const SizedBox(height: 12),
                        _buildInputField('City / Location', _locationController, Icons.location_on_outlined),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action buttons (Edit Profile / Save Changes)
                Row(
                  children: [
                    if (_isEditing)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _nameController.text = user.name;
                              _phoneController.text = user.phone;
                              _locationController.text = user.location;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    if (_isEditing) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isEditing ? _saveProfileChanges : () => setState(() => _isEditing = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          _isEditing ? 'Save Changes' : 'Edit Profile Details',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5A7569)),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD2DFD8)),
            ),
          ),
        ),
      ],
    );
  }
}
