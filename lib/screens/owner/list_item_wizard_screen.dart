import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/listing_model.dart';
import '../../services/app_store.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

class ListItemWizardScreen extends StatefulWidget {
  const ListItemWizardScreen({super.key});

  @override
  State<ListItemWizardScreen> createState() => _ListItemWizardScreenState();
}

class _ListItemWizardScreenState extends State<ListItemWizardScreen> {
  int _currentStep = 0; // 0: Basics, 1: Details, 2: Dates, 3: Preview

  // Step 1: Basics
  final _titleController = TextEditingController(text: 'Sony FX3 Cinema Camera');
  String _selectedCategory = 'Cameras';
  final _priceController = TextEditingController(text: '1200');
  final List<String> _photos = [];

  // Step 2: Details
  final _brandController = TextEditingController(text: 'Sony');
  final _modelController = TextEditingController(text: 'ILME-FX3');
  String _condition = 'Like New';
  final _depositController = TextEditingController(text: '5000');
  final _locationController = TextEditingController(text: 'Bandra West, Mumbai');
  final _descController = TextEditingController(
    text: 'Full-frame cinema line camera with XLR handle unit, dual base ISO, cooling fan, and 4K 120p video. Comes with 2 CFexpress cards.',
  );
  final List<String> _accessories = ['Camera Body', 'XLR Handle', '2x Batteries', '160GB CFexpress Card', 'Charger'];
  final _accController = TextEditingController();
  bool _deliveryOffered = true;
  final _deliveryChargeController = TextEditingController(text: '150');

  // Step 3: Dates
  int _minDays = 1;
  int _maxDays = 14;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _depositController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _accController.dispose();
    _deliveryChargeController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _submitListing() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your item.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final newListing = ListingModel(
      id: 'LIST-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _selectedCategory,
      pricePerDay: double.tryParse(_priceController.text) ?? 1000.0,
      securityDeposit: double.tryParse(_depositController.text) ?? 3000.0,
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : 'Standard',
      modelName: _modelController.text.trim(),
      condition: _condition,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : 'Available for rental.',
      includedItems: List.from(_accessories),
      imageUrls: _photos.isNotEmpty ? List.from(_photos) : ['assets/images/camera.jpg'],
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : AppStore.instance.currentUser.location,
      distanceKm: 2.0,
      ownerId: AppStore.instance.currentUser.id,
      ownerName: AppStore.instance.currentUser.name,
      ownerAvatar: AppStore.instance.currentUser.avatarUrl,
      status: ListingStatus.active,
      createdAt: DateTime.now(),
      deliveryCharge: double.tryParse(_deliveryChargeController.text) ?? 0.0,
      isDeliveryAvailable: _deliveryOffered,
    );

    await AppStore.instance.addListing(newListing);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD8F2E2),
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Item Added Successfully!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your gear "${newListing.title}" is now added and live on the RentBox marketplace.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'List an Item',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildWizardStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildNavigationFooter(),
        ],
      ),
    );
  }

  Widget _buildWizardStepper() {
    final steps = ['Basics', 'Details', 'Dates', 'Preview'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(steps.length, (i) {
            final isDone = i < _currentStep;
            final isCurrent = i == _currentStep;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent || isDone ? AppColors.primary : const Color(0xFFD8E4DD),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  steps[i],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 1,
                    color: const Color(0xFFDCE6E0),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Basics();
      case 1:
        return _buildStep2Details();
      case 2:
        return _buildStep3Dates();
      case 3:
        return _buildStep4Preview();
      default:
        return const SizedBox();
    }
  }

  bool _isUploadingPhoto = false;

  Future<void> _uploadAndAddPhoto(XFile file) async {
    final localPath = file.path;
    int photoIndex = -1;

    // Immediately display the picked photo locally in the UI
    if (mounted) {
      setState(() {
        if (_photos.length < 5) {
          _photos.add(localPath);
          photoIndex = _photos.length - 1;
        }
      });
    }

    try {
      final bytes = await file.readAsBytes();
      final uploadedUrl = await ApiService.instance.uploadImage(
        bytes,
        filename: file.name,
      );
      if (uploadedUrl != null && photoIndex >= 0 && mounted) {
        setState(() {
          if (photoIndex < _photos.length) {
            _photos[photoIndex] = uploadedUrl;
          }
        });
      }
    } catch (e) {
      debugPrint('Error uploading photo to server: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isUploadingPhoto = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file != null) {
        await _uploadAndAddPhoto(file);
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Photo added to listing! 🎉'),
              backgroundColor: Color(0xFF005C42),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Photo picker: $e. You can also pick from presets below.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickMultipleImages() async {
    setState(() => _isUploadingPhoto = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (files.isNotEmpty) {
        for (final f in files) {
          if (_photos.length < 5) {
            await _uploadAndAddPhoto(f);
          }
        }
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('${files.length} photo(s) added! 🎉'),
              backgroundColor: const Color(0xFF005C42),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Multi-photo picker: $e. You can choose photos one-by-one.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showAddPhotoSheet() {
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
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
                  'Upload Listing Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add up to 5 clear photos of your gear to get booked faster.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),

                // Device Camera & Gallery buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
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
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
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
                                'Choose Gallery',
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

                const SizedBox(height: 12),

                // Multi-photo option
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMultipleImages();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD2E6DC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.collections_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pick Multiple Photos at Once',
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

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),

                // Direct URL input
                Text(
                  'Or Paste Image URL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          hintText: 'https://images.unsplash.com/...',
                          hintStyle: const TextStyle(fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF6FAF7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD2DFD8)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final url = urlController.text.trim();
                        if (url.isNotEmpty) {
                          setState(() {
                            if (_photos.length < 5) _photos.add(url);
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Text(
                  'Quick Gear Photo Presets (1-Tap)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPresetChip(
                        ctx,
                        'Sony FX3',
                        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        ctx,
                        'Canon EOS',
                        'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=800&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        ctx,
                        'PS5 Console',
                        'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        ctx,
                        'DJI Drone',
                        'https://images.unsplash.com/photo-1508614589041-895b88991e3e?w=800&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        ctx,
                        '4K Projector',
                        'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        ctx,
                        'JBL PartyBox',
                        'https://images.unsplash.com/photo-1545454675-3531b543be5d?w=800&auto=format&fit=crop&q=80',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(BuildContext ctx, String label, String url) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_photos.length < 5) _photos.add(url);
        });
        Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7E2D3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImageWidget(pathOrUrl: url, fit: BoxFit.cover),
              Container(
                color: Colors.black38,
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Basics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Listing Photos (up to 5)'),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._photos.map((p) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 100,
                        height: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AppImageWidget(
                            pathOrUrl: p,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.remove(p)),
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )),
              if (_photos.length < 5)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showAddPhotoSheet,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC7DCD0), style: BorderStyle.solid),
                    ),
                    child: _isUploadingPhoto
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 26),
                              const SizedBox(height: 4),
                              Text('Add Photo', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              Text('${_photos.length}/5 photos', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textSecondary)),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Item Title'),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(hintText: 'e.g. Sony Alpha A7 IV'),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Category'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Cameras', 'Gaming', 'Projectors', 'Audio', 'Tech', 'Outdoor'].map((cat) {
            final isSel = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSel,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSel ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              onSelected: (_) => setState(() => _selectedCategory = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Daily Rental Rate (INR)'),
        const SizedBox(height: 6),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '₹ ',
            prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            hintText: '700',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '💡 Suggested rate for similar $_selectedCategory: ₹600 - ₹1,400/day',
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF0F7A56), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStep2Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Brand & Model'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: TextField(controller: _brandController, decoration: const InputDecoration(hintText: 'Brand (Sony)'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _modelController, decoration: const InputDecoration(hintText: 'Model (FX3)'))),
          ],
        ),
        const SizedBox(height: 18),

        _buildSectionTitle('Condition'),
        const SizedBox(height: 6),
        Row(
          children: ['Like New', 'Excellent', 'Good'].map((c) {
            final isSel = _condition == c;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _condition = c),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFE8F5EE) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSel ? AppColors.primary : const Color(0xFFDCE7E1)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    c,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? AppColors.primary : AppColors.textPrimary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        _buildSectionTitle('Refundable Security Deposit'),
        const SizedBox(height: 6),
        TextField(
          controller: _depositController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '3000'),
        ),
        const SizedBox(height: 18),

        _buildSectionTitle('Pickup Location'),
        const SizedBox(height: 6),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(hintText: 'e.g. Bandra West, Mumbai'),
        ),
        const SizedBox(height: 18),

        _buildSectionTitle('Doorstep Delivery Option'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Offer Doorstep Delivery', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold)),
          subtitle: Text('Owner handles drop-off & pick-up', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
          value: _deliveryOffered,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() => _deliveryOffered = v),
        ),
        if (_deliveryOffered)
          TextField(
            controller: _deliveryChargeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Delivery Fee (150)'),
          ),
        const SizedBox(height: 18),

        _buildSectionTitle('Description'),
        const SizedBox(height: 6),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe equipment capabilities, accessories, and maintenance notes...'),
        ),
      ],
    );
  }

  Widget _buildStep3Dates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rental Duration Restrictions'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4EDE7)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Minimum Rental Duration', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$_minDays Day', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Slider(
                value: _minDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _minDays = v.toInt()),
              ),
              const Divider(color: Color(0xFFE6EEE8), height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Maximum Rental Duration', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$_maxDays Days', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Slider(
                value: _maxDays.toDouble(),
                min: 3,
                max: 30,
                divisions: 27,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _maxDays = v.toInt()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F4EE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bookings will automatically be blocked on dates you mark unavailable in your Owner Calendar.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF163E2F)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Preview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4EDE7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                child: AppImageWidget(
                  pathOrUrl: _photos.isNotEmpty ? _photos.first : 'assets/images/camera.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_titleController.text, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('₹${_priceController.text}/day', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Location: ${_locationController.text}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(_descController.text, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF384D44))),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Deposit: ₹${_depositController.text}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Condition: $_condition', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildNavigationFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_currentStep < 3) {
                          setState(() => _currentStep++);
                        } else {
                          _submitListing();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _currentStep == 3 ? 'Publish Item' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
