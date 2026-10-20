import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminKycScreen extends StatefulWidget {
  const AdminKycScreen({super.key});

  @override
  State<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends State<AdminKycScreen> {
  final List<Map<String, dynamic>> _applicants = [
    {
      'id': 'KYC-01',
      'name': 'Kunal Verma',
      'phone': '+91 98201 11234',
      'docType': 'Aadhaar Card + GSTIN',
      'docNum': 'XXXX-XXXX-4912',
      'status': 'Pending Verification',
      'submitted': '2 hours ago',
      'avatar': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop&q=80',
    },
    {
      'id': 'KYC-02',
      'name': 'Priya Chawla',
      'phone': '+91 98190 88231',
      'docType': 'PAN Card + Utility Bill',
      'docNum': 'ABCDE1234F',
      'status': 'Pending Verification',
      'submitted': '5 hours ago',
      'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=80',
    },
    {
      'id': 'KYC-03',
      'name': 'Rajesh Sharma',
      'phone': '+91 98765 12345',
      'docType': 'Passport + Aadhaar',
      'docNum': 'P9821345',
      'status': 'Verified',
      'submitted': '12 days ago',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    },
  ];

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
          'Owner KYC Verification',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: _applicants.length,
        itemBuilder: (context, i) {
          final a = _applicants[i];
          final isPending = a['status'] == 'Pending Verification';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4EDE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(a['avatar'] as String),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['name'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text('${a['phone']} • ${a['submitted']}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        a['status'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPending ? const Color(0xFF92400E) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FAF7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('${a['docType']}: ${a['docNum']}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => a['status'] = 'Rejected (Resubmit)');
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => a['status'] = 'Verified');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${a['name']} KYC Approved!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Approve KYC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
