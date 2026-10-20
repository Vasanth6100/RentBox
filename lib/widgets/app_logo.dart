import 'package:flutter/material.dart';

enum LogoBadgeType { none, lock, checkmark }

class RentBoxLogo extends StatelessWidget {
  final double size;
  final LogoBadgeType badgeType;
  final bool isCircle;

  const RentBoxLogo({
    super.key,
    this.size = 80,
    this.badgeType = LogoBadgeType.none,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Authentic RentBox Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(isCircle ? size / 2 : size * 0.22),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image fails to load
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005C42),
                    borderRadius: BorderRadius.circular(size * 0.22),
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: size * 0.55),
                );
              },
            ),
          ),

          // Optional attached badge at bottom right
          if (badgeType != LogoBadgeType.none)
            Positioned(
              right: -size * 0.05,
              bottom: -size * 0.05,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF004D36),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    badgeType == LogoBadgeType.lock
                        ? Icons.lock_rounded
                        : Icons.check_rounded,
                    size: size * 0.18,
                    color: badgeType == LogoBadgeType.checkmark
                        ? const Color(0xFF34D399)
                        : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
