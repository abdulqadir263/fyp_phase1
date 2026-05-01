import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../expert/controllers/expert_auth_controller.dart';
import '../../seller/controllers/seller_auth_controller.dart';

/// Shared email verification pending screen for Expert and Seller.
/// Route args: { email: String, role: 'expert'|'seller'|'farmer', uid: String }
///
/// For Farmer email-auth this same screen is reused.
class EmailVerificationPendingView extends StatefulWidget {
  const EmailVerificationPendingView({super.key});

  @override
  State<EmailVerificationPendingView> createState() =>
      _EmailVerificationPendingViewState();
}

class _EmailVerificationPendingViewState
    extends State<EmailVerificationPendingView> {
  late final String _email;
  late final String _role;
  late final String _uid;

  final _checking = false.obs;
  final _notVerifiedMsg = ''.obs;
  final _resendCooldown = 0.obs;
  Timer? _timer;

  Color get _roleColor {
    switch (_role) {
      case 'expert':
        return const Color(0xFF1565C0);
      case 'seller':
        return const Color(0xFFE65100);
      default:
        return AppConstants.primaryGreen;
    }
  }



  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    _email = args['email'] as String;
    _role = args['role'] as String;
    _uid = args['uid'] as String;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    _checking.value = true;
    _notVerifiedMsg.value = '';

    bool verified = false;

    try {
      switch (_role) {
        case 'expert':
          final ctrl = Get.find<ExpertAuthController>();
          verified = await ctrl.checkEmailVerified(_uid);
          break;
        case 'seller':
          final ctrl = Get.find<SellerAuthController>();
          verified = await ctrl.checkEmailVerified(_uid);
          break;
        case 'farmer':
          // Farmer uses ExpertAuthController-equivalent via FarmerAuthController
          // We reload and check manually here
          verified = await _checkFarmerVerification();
          break;
      }
    } catch (_) {}

    if (!verified) {
      _notVerifiedMsg.value =
          'Not verified yet. Please check your inbox.';
    }
    _checking.value = false;
  }

  Future<bool> _checkFarmerVerification() async {
    // Import lazily to avoid circular dependencies
    try {
      final farmerCtrl = Get.find(tag: 'farmerAuth');
      if (farmerCtrl != null) {
        // ignore: avoid_dynamic_calls
        return await farmerCtrl.reloadAndCheckVerification();
      }
    } catch (_) {}

    // Fallback: reload Firebase user directly
    try {
      final isVerified = await _reloadFirebaseUser();
      if (isVerified) {
          // Update emailVerified flag in farmers collection
          await _updateFarmerVerifiedFlag();
          // Navigate to home
          Get.offAllNamed(AppRoutes.HOME);
          return true;
        }
      } catch (_) {}
    return false;
  }

  Future<bool> _reloadFirebaseUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _updateFarmerVerifiedFlag() async {}

  Future<void> _resend() async {
    if (_resendCooldown.value > 0) return;
    _startCooldown();

    switch (_role) {
      case 'expert':
        await Get.find<ExpertAuthController>().resendVerificationEmail();
        break;
      case 'seller':
        await Get.find<SellerAuthController>().resendVerificationEmail();
        break;
      default:
        // Farmer email resend
        break;
    }
  }

  void _startCooldown() {
    _resendCooldown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown.value <= 0) {
        t.cancel();
      } else {
        _resendCooldown.value--;
      }
    });
  }

  void _useDifferentEmail() {
    switch (_role) {
      case 'expert':
        Get.offAllNamed(AppRoutes.EXPERT_AUTH);
        break;
      case 'seller':
        Get.offAllNamed(AppRoutes.SELLER_AUTH);
        break;
      default:
        Get.offAllNamed(AppRoutes.FARMER_SIGNUP);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // ── Icon ──────────────────────────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      color: _roleColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[500], height: 1.5),
                      children: [
                        const TextSpan(
                            text:
                                'We sent a verification link to\n'),
                        TextSpan(
                          text: _email,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700]),
                        ),
                        const TextSpan(
                            text: '\nPlease check your inbox.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Check verified button ─────────────────────────────────
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _checking.value ? null : _checkVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _roleColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _checking.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "I've verified my email",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      )),

                  const SizedBox(height: 12),

                  // ── Not verified error ────────────────────────────────────
                  Obx(() {
                    final msg = _notVerifiedMsg.value;
                    if (msg.isEmpty) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        msg,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // ── Resend ────────────────────────────────────────────────
                  Obx(() => _resendCooldown.value > 0
                      ? Text(
                          'Resend available in ${_resendCooldown.value}s',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13),
                        )
                      : TextButton.icon(
                          onPressed: _resend,
                          icon: Icon(Icons.refresh, color: _roleColor, size: 18),
                          label: Text(
                            'Resend verification email',
                            style: TextStyle(
                                color: _roleColor,
                                fontWeight: FontWeight.w500),
                          ),
                        )),

                  const SizedBox(height: 12),

                  // ── Different email ───────────────────────────────────────
                  TextButton(
                    onPressed: _useDifferentEmail,
                    child: Text(
                      'Use a different email',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
