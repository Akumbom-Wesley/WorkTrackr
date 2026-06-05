import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headlineXl = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.22,
    letterSpacing: -0.72,
    color: Color(0xFF0B1C30),
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: -0.28,
    color: Color(0xFF0B1C30),
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
    color: Color(0xFF0B1C30),
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Color(0xFF0B1C30),
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xFF0B1C30),
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: Color(0xFF0B1C30),
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.24,
    color: Color(0xFF45464D),
  );

  static const TextStyle labelXs = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: Color(0xFF45464D),
  );

  // Legacy aliases
  static const TextStyle display = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimary,
  );

  static const TextStyle heading = headlineMd;
  static const TextStyle body    = bodyMd;
  static const TextStyle caption = labelSm;

  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimary,
  );
}
