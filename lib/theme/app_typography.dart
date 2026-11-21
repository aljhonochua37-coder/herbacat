import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// HerbaCat Typography from Stitch project 'herbacat1'
class AppTypography {
  // Display & Headlines (Bricolage Grotesque)
  static TextStyle displayLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.02,
      color: color,
    );
  }

  static TextStyle headlineLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.01,
      color: color,
    );
  }

  static TextStyle headlineMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color,
    );
  }

  static TextStyle headlineSm({Color color = AppColors.onSurface}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: color,
    );
  }

  // Body & Labels (Hanken Grotesk)
  static TextStyle bodyLg({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodyMd({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle bodySm({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle labelLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.01,
      color: color,
    );
  }

  static TextStyle labelMd({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.02,
      color: color,
    );
  }

  static TextStyle labelSm({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0.03,
      color: color,
    );
  }
}

