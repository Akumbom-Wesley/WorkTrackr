import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    // TODO: wire to auth provider
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // Logo mark
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security,
                  size: 40,
                  color: AppColors.onPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // Wordmark
              Text(
                'WorkTrackr',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: AppColors.onBackground,
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Secure Employee Portal',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // Login card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBase,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceMuted),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          'System\nAccess',
                          style: AppTextStyles.headlineMd.copyWith(
                            color: AppColors.onBackground,
                          ),
                        ),
                        _EncryptedChip(),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Employee ID field
                    Text(
                      'ERPNext Employee ID',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeIdController,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onBackground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. SET-1042',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.outline,
                        ),
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.outline,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password field
                    Text(
                      'Password',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onBackground,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.outline,
                        ),
                        prefixIcon: const Icon(
                          Icons.key_outlined,
                          color: AppColors.outline,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.outline,
                            size: 20,
                          ),
                          onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                            : const Icon(Icons.login, size: 18),
                        label: Text(
                          'Login',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // New Employee link
              Text(
                'New Employee?',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 6),

              GestureDetector(
                onTap: () {
                  // TODO: navigate to set password screen
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Set Initial Password',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncryptedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 12,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 5),
          Text(
            'ENCRYPTED\nCONNECTION',
            style: AppTextStyles.labelXs.copyWith(
              color: AppColors.secondary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}