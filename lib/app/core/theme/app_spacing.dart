/// Design tokens — absolute pixel values, no `flutter_screenutil`.
/// Reason: app targets BOTH tablet (Android, ~10–13") and Windows desktop
/// (1920×1080+). A single screenutil baseline distorts on one of them.
/// Use these constants directly; rely on `MediaQuery` breakpoints for
/// layout switching, not for sizing.
class AppSpacing {
  AppSpacing._();

  // Base unit (4dp grid)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Touch targets — gloves-friendly
  static const double touchMin = 48;
  static const double buttonHeight = 56;
  static const double numpadButton = 72;

  // Page padding
  static const double pagePaddingTablet = 24;
  static const double pagePaddingDesktop = 32;

  // Border radius
  static const double radiusInput = 4;
  static const double radiusButton = 8;
  static const double radiusCard = 12;
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double tabletPortrait = 600;
  static const double tabletLandscape = 840;
  static const double desktop = 1200;

  /// True when window width suggests desktop layout (NavigationRail).
  static bool isDesktop(double width) => width >= desktop;

  /// True when wide enough for master-detail (list + detail side by side).
  static bool isMasterDetail(double width) => width >= tabletLandscape;
}
