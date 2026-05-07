import 'package:flutter/material.dart';

/// Palette derived from the TCS Tech logo (4 chevrons + yellow wordmark).
/// Brand-aligned with the sister Flutter app `odoo_attendance`.
class AppColors {
  AppColors._();

  // Brand — green chevron (most prominent in the logo) → primary action.
  static const Color primary = Color(0xFF16A34A);       // green-600
  static const Color primaryDark = Color(0xFF15803D);   // green-700
  static const Color primaryLight = Color(0xFF4ADE80);  // green-400

  // Other chevron + wordmark colours, mapped to semantic roles:
  static const Color accent = Color(0xFF2563EB);        // blue chevron → info / draft
  static const Color success = Color(0xFF16A34A);       // same green → done / OK qty
  static const Color warning = Color(0xFFF59E0B);       // yellow wordmark → in-progress / pause
  static const Color error = Color(0xFFDC2626);         // red chevron → NG / cancel

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color divider = Color(0xFFE5E7EB);
  static const Color disabled = Color(0xFFD1D5DB);
}
