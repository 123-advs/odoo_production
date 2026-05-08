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

  static bool isDesktop(double width) => width >= desktop;

  static bool isMasterDetail(double width) => width >= tabletLandscape;
}
