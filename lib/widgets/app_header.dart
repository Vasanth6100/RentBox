import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

class RentBoxHeader extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final bool showProfile;
  final VoidCallback? onProfile;

  const RentBoxHeader({
    super.key,
    this.showBack = true,
    this.onBack,
    this.showProfile = true,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              splashRadius: 24,
            )
          else
            const SizedBox(width: 48),

          // Central logo + branding
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RentBoxLogo(
                size: 32,
                badgeType: LogoBadgeType.none,
                isCircle: false,
              ),
              const SizedBox(width: 8),
              Text(
                'RentBox',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          if (showProfile)
            InkWell(
              onTap: onProfile,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
