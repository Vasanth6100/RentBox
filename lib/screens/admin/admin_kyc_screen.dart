import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminKycScreen extends StatefulWidget {
  const AdminKycScreen({super.key});

  @override
  State<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends State<AdminKycScreen> {
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKycApplicants();
  }

  Future<void> _loadKycApplicants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.getKycApplicants();
      if (!mounted) return;
      setState(() {
        _applicants = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load KYC applications.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateKycStatus(Map<String, dynamic> a, String newStatus) async {
    try {
      await ApiService.instance.updateKycStatus(
        userId: a['id'] as String,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() => a['kycStatus'] = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'verified'
                ? '${a['name']} KYC Approved!'
                : '${a['name']} KYC Rejected.',
          ),
          backgroundColor: newStatus == 'verified'
              ? const Color(0xFF005C42)
              : Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update KYC status.')),
      );
    }
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
          'Owner KYC Verification',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadKycApplicants,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: GoogleFonts.plusJakartaSans(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadKycApplicants,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _applicants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 52, color: Color(0xFF9DC4B0)),
                          const SizedBox(height: 12),
                          Text(
                            'No KYC applications found.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadKycApplicants,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: _applicants.length,
                        itemBuilder: (context, i) {
                          final a = _applicants[i];
                          final kycStatus = (a['kycStatus'] ?? a['kyc_status'] ?? 'pending') as String;
                          final isPending = kycStatus == 'pending' || kycStatus == 'under_review';
                          final statusLabel = isPending
                              ? 'Pending Verification'
                              : kycStatus == 'verified'
                                  ? 'Verified'
                                  : 'Rejected';

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
                                      backgroundColor: const Color(0xFFE2EFE7),
                                      backgroundImage: (a['avatarUrl'] ?? a['avatar_url'] ?? '') != ''
                                          ? NetworkImage(a['avatarUrl'] ?? a['avatar_url'] ?? '')
                                          : null,
                                      child: (a['avatarUrl'] ?? a['avatar_url'] ?? '') == ''
                                          ? Text(
                                              ((a['name'] as String?) ?? 'U')[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a['name'] as String? ?? 'Unknown',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${a['phone'] ?? a['email'] ?? ''}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? const Color(0xFFFEF3C7)
                                            : kycStatus == 'verified'
                                                ? const Color(0xFFD1FAE5)
                                                : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isPending
                                              ? const Color(0xFF92400E)
                                              : kycStatus == 'verified'
                                                  ? const Color(0xFF065F46)
                                                  : const Color(0xFF991B1B),
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
                                      Expanded(
                                        child: Text(
                                          a['idDocumentType'] ?? a['id_document_type'] ?? 'KYC Document',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isPending) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _updateKycStatus(a, 'rejected'),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateKycStatus(a, 'verified'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                          ),
                                          child: const Text(
                                            'Approve KYC',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                    ),
    );
  }
}
