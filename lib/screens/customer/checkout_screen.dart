import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/listing_model.dart';
import '../../models/booking_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import 'bookings_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final ListingModel listing;

  const CheckoutScreen({
    super.key,
    required this.listing,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 4));
  FulfillmentMethod _fulfillment = FulfillmentMethod.selfPickup;
  ProtectionPlan _protection = ProtectionPlan.standard;
  String _paymentMethod = 'UPI (GPay / PhonePe)';
  bool _isProcessing = false;

  int get _durationDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _rentalFee => widget.listing.pricePerDay * _durationDays;
  double get _securityDeposit => widget.listing.securityDeposit;
  double get _deliveryFee => _fulfillment == FulfillmentMethod.ownerDelivery
      ? widget.listing.deliveryCharge
      : 0.0;
  double get _protectionFee => _protection == ProtectionPlan.standard
      ? 99.0
      : (_protection == ProtectionPlan.basic ? 49.0 : 0.0);
  double get _taxes => (_rentalFee * 0.05).roundToDouble();
  double get _totalPayable => _rentalFee + _securityDeposit + _deliveryFee + _protectionFee + _taxes;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final booking = await AppStore.instance.createBooking(
        listing: widget.listing,
        startDate: _startDate,
        endDate: _endDate,
        fulfillmentMethod: _fulfillment,
        protectionPlan: _protection,
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog(booking);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm booking: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessDialog(BookingModel booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD8F2E2),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Booking Confirmed! 🎉',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your reservation for "${widget.listing.title}" is locked in.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pickup Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        booking.pickupCode,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFDDE7E1), height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '₹${booking.totalPayable.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx); // close dialog
                  Navigator.pop(context); // pop checkout
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('View in My Rentals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;
    final dateFmt = DateFormat('dd MMM yyyy');

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
          'Checkout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress step indicator
            _buildStepIndicator(),
            const SizedBox(height: 16),

            // Product summary card
            _buildItemSummaryCard(item),
            const SizedBox(height: 16),

            // Rental Duration card
            _buildDurationCard(dateFmt),
            const SizedBox(height: 16),

            // Fulfilment method card
            _buildFulfillmentCard(),
            const SizedBox(height: 16),

            // Protection plan card
            _buildProtectionCard(),
            const SizedBox(height: 16),

            // Payment method selector
            _buildPaymentMethodCard(),
            const SizedBox(height: 16),

            // Fare breakdown calculation
            _buildFareBreakdownCard(),
            const SizedBox(height: 24),

            // Pay & Confirm button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pay ₹${_totalPayable.toStringAsFixed(0)} & Confirm',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '🔒 Secured by 256-bit encryption • Deposit 100% Refundable',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem('1', 'Dates', active: true),
          _buildStepDivider(),
          _buildStepItem('2', 'Fulfilment', active: true),
          _buildStepDivider(),
          _buildStepItem('3', 'Payment', active: true),
        ],
      ),
    );
  }

  Widget _buildStepItem(String num, String title, {required bool active}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : const Color(0xFFD0DDD6),
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 24,
      height: 1,
      color: const Color(0xFFD6E3DC),
    );
  }

  Widget _buildItemSummaryCard(ListingModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 76,
              height: 76,
              child: AppImageWidget(
                pathOrUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Owner: ${item.ownerName} • ${item.location}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${item.pricePerDay.toStringAsFixed(0)} / day',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(DateFormat dateFmt) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rental Duration',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: _selectDateRange,
                child: Text(
                  'Change Dates',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${dateFmt.format(_startDate)}  →  ${dateFmt.format(_endDate)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_durationDays ${_durationDays == 1 ? 'day' : 'days'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fulfilment Method',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFulfillmentOption(
                  method: FulfillmentMethod.selfPickup,
                  title: 'Self Pickup',
                  subtitle: 'Free (${widget.listing.location})',
                  icon: Icons.store_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFulfillmentOption(
                  method: FulfillmentMethod.ownerDelivery,
                  title: 'Doorstep',
                  subtitle: widget.listing.isDeliveryAvailable
                      ? '₹${widget.listing.deliveryCharge.toStringAsFixed(0)} delivery'
                      : 'Not Available',
                  icon: Icons.local_shipping_outlined,
                  disabled: !widget.listing.isDeliveryAvailable,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentOption({
    required FulfillmentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    bool disabled = false,
  }) {
    final isSelected = _fulfillment == method;

    return InkWell(
      onTap: disabled ? null : () => setState(() => _fulfillment = method),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5EE) : const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2EBE5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protection Plan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildProtectionRadio(
            plan: ProtectionPlan.standard,
            title: 'Standard Protection (Recommended)',
            desc: 'Covers accidental scratches & damage up to ₹25,000.',
            price: '₹99',
          ),
          const SizedBox(height: 8),
          _buildProtectionRadio(
            plan: ProtectionPlan.basic,
            title: 'Basic Protection',
            desc: 'Covers minor operational wear & tear up to ₹5,000.',
            price: '₹49',
          ),
          const SizedBox(height: 8),
          _buildProtectionRadio(
            plan: ProtectionPlan.none,
            title: 'No Protection',
            desc: 'Renter liable for full damage & replacement value.',
            price: '₹0',
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionRadio({
    required ProtectionPlan plan,
    required String title,
    required String desc,
    required String price,
  }) {
    final isSelected = _protection == plan;

    return InkWell(
      onTap: () => setState(() => _protection = plan),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5EE) : const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2EBE5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final methods = [
      {'name': 'UPI (GPay / PhonePe)', 'icon': Icons.account_balance_wallet_outlined},
      {'name': 'Credit / Debit Card', 'icon': Icons.credit_card_outlined},
      {'name': 'Net Banking', 'icon': Icons.account_balance_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...methods.map((m) {
            final isSelected = _paymentMethod == m['name'];
            return InkWell(
              onTap: () => setState(() => _paymentMethod = m['name'] as String),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(m['icon'] as IconData, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFareBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildFareRow('Rental Fee ($_durationDays days)', '₹${_rentalFee.toStringAsFixed(0)}'),
          _buildFareRow('Refundable Security Deposit', '₹${_securityDeposit.toStringAsFixed(0)}', isDeposit: true),
          if (_deliveryFee > 0) _buildFareRow('Doorstep Delivery Fee', '₹${_deliveryFee.toStringAsFixed(0)}'),
          if (_protectionFee > 0) _buildFareRow('Damage Protection Plan', '₹${_protectionFee.toStringAsFixed(0)}'),
          _buildFareRow('Platform Tax (5%)', '₹${_taxes.toStringAsFixed(0)}'),
          const Divider(color: Color(0xFFE4EDE7), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${_totalPayable.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Includes ₹${_securityDeposit.toStringAsFixed(0)} refundable security deposit refunded after return.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF0D7A56),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String title, String val, {bool isDeposit = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: isDeposit ? const Color(0xFF0F7A56) : AppColors.textSecondary,
              fontWeight: isDeposit ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
