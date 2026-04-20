import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler - Daha uyumlu mavi tonları
  static const Color primaryColor = Color(0xFF2196F3); // Material Blue
  static const Color primaryLightColor = Color(0xFF64B5F6); // Açık mavi
  static const Color primaryDarkColor = Color(0xFF1976D2); // Koyu mavi
  
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color accentLightColor = Color(0xFF4DD0E1); // Açık cyan
  
  // Yardımcı renkler - Daha yumuşak tonlar
  static const Color successColor = Color(0xFF4CAF50); // Yeşil
  static const Color warningColor = Color(0xFFFF9800); // Turuncu
  static const Color errorColor = Color(0xFFF44336); // Kırmızı
  static const Color infoColor = Color(0xFF2196F3); // Mavi
  
  // Gri tonları - Göz yormayan
  static const Color greyLight = Color(0xFFFAFAFA); // Çok açık gri
  static const Color greyMedium = Color(0xFF9E9E9E); // Orta gri
  static const Color greyDark = Color(0xFF616161); // Koyu gri
  static const Color textPrimary = Color(0xFF212121); // Ana metin rengi
  static const Color textSecondary = Color(0xFF757575); // İkincil metin rengi
  
  // Durum renkleri - Daha yumuşak
  static const Color beklemedeDurum = Color(0xFFFF9800); // Turuncu
  static const Color planlamaDurum = Color(0xFF2196F3); // Mavi
  static const Color uretimDurum = Color(0xFF9C27B0); // Mor
  static const Color tamamlandiDurum = Color(0xFF4CAF50); // Yeşil
  static const Color iptalDurum = Color(0xFFF44336); // Kırmızı

  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: primaryColor,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: textPrimary,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      toolbarHeight: 44,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 13),
        elevation: 1,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 13),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 13),
      ),
    ),
    
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(4),
        minimumSize: const Size(32, 32),
        iconSize: 20,
      ),
    ),
    
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(3),
      color: Colors.white,
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: greyMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: greyMedium),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: greyMedium, fontSize: 13),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 3,
      sizeConstraints: BoxConstraints.tightFor(width: 48, height: 48),
    ),
    
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 13,
        color: textSecondary,
      ),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 13),
    ),
    
    dataTableTheme: DataTableThemeData(
      headingRowHeight: 40,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 44,
      columnSpacing: 16,
      horizontalMargin: 12,
      headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
      dataTextStyle: const TextStyle(fontSize: 12, color: textPrimary),
    ),
    
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(fontSize: 13),
    ),
    
    popupMenuTheme: const PopupMenuThemeData(
      textStyle: TextStyle(fontSize: 13),
    ),
    
    scaffoldBackgroundColor: greyLight,
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 11,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        color: textSecondary,
      ),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: greyLight,
      labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
    
    listTileTheme: const ListTileThemeData(
      dense: true,
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 4,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      textColor: textPrimary,
      titleTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
      subtitleTextStyle: TextStyle(fontSize: 12, color: textSecondary),
    ),
    
    iconTheme: const IconThemeData(size: 20),
    
    useMaterial3: true,
  );
  
  // Durum rengi alma fonksiyonu
  static Color getDurumRengi(String? durum) {
    switch (durum) {
      case 'Beklemede':
        return beklemedeDurum;
      case 'Planlama':
        return planlamaDurum;
      case 'Üretim':
        return uretimDurum;
      case 'Tamamlandı':
        return tamamlandiDurum;
      case 'İptal':
        return iptalDurum;
      default:
        return greyMedium;
    }
  }
  
  // Termin tarihine göre renk alma fonksiyonu
  static Color getTerminRengi(String? terminTarihi) {
    if (terminTarihi == null) return Colors.white;
    
    final termin = DateTime.tryParse(terminTarihi);
    if (termin == null) return Colors.white;
    
    final now = DateTime.now();
    final kalanGun = termin.difference(now).inDays;
    
    if (kalanGun < 0) {
      return errorColor.withValues(alpha: 0.3); // Termin tarihi geçmiş
    } else if (kalanGun <= 7) {
      return warningColor.withValues(alpha: 0.3); // Son 7 gün
    } else if (kalanGun <= 15) {
      return Colors.yellow.withValues(alpha: 0.3); // Son 15 gün
    }
    return Colors.white; // Normal durum
  }
}
