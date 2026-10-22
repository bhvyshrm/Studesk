import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/studesk_wordmark.dart';
import '../../profile/data/profile_service.dart';
import '../data/auth_service.dart';

/// Dedicated, strict monochrome username onboarding screen for first-time students.
/// AMOLED Black background (#000000), White text (#FFFFFF), and neutral gray borders.
class UsernameOnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const UsernameOnboardingScreen({super.key, required this.onCompleted});

  @override
  State<UsernameOnboardingScreen> createState() =>
      _UsernameOnboardingScreenState();
}

enum _AvailabilityStatus { idle, checking, available, taken, invalid, reserved }

class _UsernameOnboardingScreenState extends State<UsernameOnboardingScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ProfileService _profileService = ProfileService.instance;

  Timer? _debounceTimer;
  _AvailabilityStatus _status = _AvailabilityStatus.idle;
  String? _statusMessage;
  String? _saveErrorMessage;
  bool _isSaving = false;

  static const Color _bgAmoled = Color(0xFF000000);
  static const Color _surfaceCard = Color(0xFF0F0F12);
  static const Color _surfaceInput = Color(0xFF18181C);
  static const Color _borderNeutral = Color(0xFF2B2B33);
  static const Color _borderActive = Color(0xFF555562);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFA2A2AE);
  static const Color _textMuted = Color(0xFF6B6B76);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final raw = _controller.text;
    final lower = raw.toLowerCase().replaceAll(' ', '_');
    if (raw != lower) {
      final selection = _controller.selection;
      _controller.value = _controller.value.copyWith(
        text: lower,
        selection: selection,
      );
      return;
    }

    _debounceTimer?.cancel();
    setState(() {
      _saveErrorMessage = null;
    });

    final trimmed = lower.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _status = _AvailabilityStatus.idle;
        _statusMessage = null;
      });
      return;
    }

    final validationError = _profileService.validateUsername(trimmed);
    if (validationError != null) {
      setState(() {
        _status = validationError.contains('reserved')
            ? _AvailabilityStatus.reserved
            : _AvailabilityStatus.invalid;
        _statusMessage = validationError;
      });
      return;
    }

    // Set checking state and debounce network request
    setState(() {
      _status = _AvailabilityStatus.checking;
      _statusMessage = 'Checking availability...';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final isAvailable = await _profileService.checkUsernameAvailable(trimmed);
      if (!mounted || _controller.text.trim().toLowerCase() != trimmed) return;

      setState(() {
        if (isAvailable) {
          _status = _AvailabilityStatus.available;
          _statusMessage = '@$trimmed is available';
        } else {
          _status = _AvailabilityStatus.taken;
          _statusMessage = '@$trimmed is already taken by another student';
        }
      });
    });
  }

  Future<void> _handleContinue() async {
    final username = _controller.text.trim().toLowerCase();
    final validationError = _profileService.validateUsername(username);
    if (validationError != null) {
      setState(() {
        _status = _AvailabilityStatus.invalid;
        _statusMessage = validationError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await _profileService.claimUsername(username);
      if (mounted) {
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveErrorMessage = e.toString().replaceFirst('Exception: ', '');
          if (_saveErrorMessage!.toLowerCase().contains('taken') ||
              _saveErrorMessage!.toLowerCase().contains('claimed')) {
            _status = _AvailabilityStatus.taken;
            _statusMessage = '@$username is already taken';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool get _canContinue =>
      _status == _AvailabilityStatus.available &&
      !_isSaving &&
      _saveErrorMessage == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgAmoled,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: StuDesk Wordmark + Sign Out Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const StuDeskWordmark(fontSize: 20, showDot: true),
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            await AuthService.instance.signOut();
                          },
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: _textSecondary,
                    ),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: _borderNeutral, height: 1),

            // Center Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Identification Emblem
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: _surfaceCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _borderNeutral,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '@',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Choose your username',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: _textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Your username identifies you inside StuDesk across courses, study desks, and academic records.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 28),

                        // Username Setup Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _surfaceCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _borderNeutral),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Input Field Label
                              const Text(
                                'STUDENT USERNAME',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: _textMuted,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Text Input
                              Container(
                                decoration: BoxDecoration(
                                  color: _surfaceInput,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _focusNode.hasFocus
                                        ? _borderActive
                                        : _borderNeutral,
                                  ),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textCapitalization: TextCapitalization.none,
                                  keyboardType: TextInputType.text,
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                  decoration: InputDecoration(
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 14,
                                        right: 4,
                                      ),
                                      child: Text(
                                        '@',
                                        style: TextStyle(
                                          color: _textMuted,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                    suffixIcon: _buildSuffixIcon(),
                                    hintText: 'alex_chen',
                                    hintStyle: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                  ),
                                  onSubmitted: (_) {
                                    if (_canContinue) {
                                      _handleContinue();
                                    }
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Format Guidance
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 13,
                                    color: _textMuted,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '3–20 characters. Lowercase letters, numbers, and underscores only.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: _textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Dynamic Status / Feedback Row
                              if (_statusMessage != null) ...[
                                const SizedBox(height: 12),
                                _buildStatusIndicator(),
                              ],

                              // Save Error Banner
                              if (_saveErrorMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F1212),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF4A2828),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 16,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _saveErrorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFEEEEEE),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Continue Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canContinue
                                  ? _textPrimary
                                  : const Color(0xFF222228),
                              foregroundColor: _canContinue
                                  ? const Color(0xFF000000)
                                  : _textMuted,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: _canContinue
                                      ? _textPrimary
                                      : _borderNeutral,
                                ),
                              ),
                            ),
                            onPressed: _canContinue ? _handleContinue : null,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFF000000),
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    switch (_status) {
      case _AvailabilityStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _textSecondary,
            ),
          ),
        );
      case _AvailabilityStatus.available:
        return const Icon(
          Icons.check_circle_outline_rounded,
          color: _textPrimary,
          size: 20,
        );
      case _AvailabilityStatus.taken:
      case _AvailabilityStatus.reserved:
      case _AvailabilityStatus.invalid:
        return const Icon(
          Icons.cancel_outlined,
          color: _textSecondary,
          size: 20,
        );
      case _AvailabilityStatus.idle:
        return null;
    }
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color iconColor;
    Color textColor;

    switch (_status) {
      case _AvailabilityStatus.available:
        icon = Icons.check_circle_rounded;
        iconColor = _textPrimary;
        textColor = _textPrimary;
        break;
      case _AvailabilityStatus.taken:
      case _AvailabilityStatus.reserved:
      case _AvailabilityStatus.invalid:
        icon = Icons.info_outline_rounded;
        iconColor = _textSecondary;
        textColor = _textSecondary;
        break;
      case _AvailabilityStatus.checking:
        icon = Icons.hourglass_top_rounded;
        iconColor = _textMuted;
        textColor = _textMuted;
        break;
      case _AvailabilityStatus.idle:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceInput,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderNeutral),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage ?? '',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
