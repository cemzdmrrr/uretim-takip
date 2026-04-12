import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/config/database_tables.dart';

/// Pure utility functions for model_detay — no state dependency.

String? formatDate(dynamic date) {
  if (date == null) return null;
  try {
    final dt = DateTime.parse(date.toString());
    return DateFormat('dd.MM.yyyy').format(dt);
  } catch (e) {
    return date.toString();
  }
}

String hesaplaSure(DateTime baslangic, DateTime? bitis) {
  final son = bitis ?? DateTime.now();
  final fark = son.difference(baslangic);

  if (fark.inDays > 0) {
    return '${fark.inDays} gün ${fark.inHours % 24} saat';
  } else if (fark.inHours > 0) {
    return '${fark.inHours} saat ${fark.inMinutes % 60} dakika';
  } else {
    return '${fark.inMinutes} dakika';
  }
}

/// Maps stage code → Supabase table name (atama tables).
String? getTabloAdi(String asamaKodu) {
  switch (asamaKodu.toLowerCase()) {
    case 'dokuma':
      return DbTables.dokumaAtamalari;
    case 'konfeksiyon':
      return DbTables.konfeksiyonAtamalari;
    case 'yikama':
      return DbTables.yikamaAtamalari;
    case 'utu':
      return DbTables.utuAtamalari;
    case 'paketleme':
      return DbTables.paketlemeAtamalari;
    case 'ilik_dugme':
      return DbTables.ilikDugmeAtamalari;
    case 'nakis':
      return DbTables.nakisAtamalari;
    case 'kalite_kontrol':
      return DbTables.kaliteKontrolAtamalari;
    default:
      return null;
  }
}

/// Maps stage key (orgu, konfeksiyon…) → Supabase table name.
String getTableNameForStage(String asamaKey) {
  switch (asamaKey) {
    case 'orgu':
      return DbTables.dokumaAtamalari;
    case 'konfeksiyon':
      return DbTables.konfeksiyonAtamalari;
    case 'nakis':
      return DbTables.nakisAtamalari;
    case 'yikama':
      return DbTables.yikamaAtamalari;
    case 'ilik_dugme':
      return DbTables.ilikDugmeAtamalari;
    case 'utu':
      return DbTables.utuAtamalari;
    default:
      return DbTables.dokumaAtamalari;
  }
}

String getAsamaDisplayName(String asamaKey) {
  switch (asamaKey) {
    case 'orgu':
      return 'Dokuma/Örgü';
    case 'konfeksiyon':
      return 'Konfeksiyon';
    case 'nakis':
      return 'Nakış';
    case 'yikama':
      return 'Yıkama';
    case 'ilik_dugme':
      return 'İlik Düğme';
    case 'utu':
      return 'Ütü';
    default:
      return asamaKey;
  }
}

Color getStatusColor(String? durum) {
  switch (durum?.toLowerCase()) {
    case 'atandi':
    case 'firma_onay_bekliyor':
      return Colors.orange;
    case 'baslatildi':
    case 'uretimde':
      return Colors.blue;
    case 'tamamlandi':
      return Colors.green;
    case 'iptal':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String getStatusText(String? durum) {
  switch (durum?.toLowerCase()) {
    case 'atandi':
      return 'Atandı';
    case 'firma_onay_bekliyor':
      return 'Onay Bekliyor';
    case 'baslatildi':
      return 'Başlatıldı';
    case 'uretimde':
      return 'Üretimde';
    case 'tamamlandi':
      return 'Tamamlandı';
    case 'iptal':
      return 'İptal';
    default:
      return durum ?? 'Bilinmiyor';
  }
}

IconData getDurumIkonu(String durum) {
  switch (durum) {
    case 'Tamamlandı':
      return Icons.check_circle;
    case 'İşleniyor':
      return Icons.autorenew;
    case 'Atanmış':
      return Icons.assignment;
    default:
      return Icons.schedule;
  }
}

IconData getDosyaIcon(String? tip) {
  switch (tip) {
    case 'teknik_cizim':
      return Icons.architecture;
    case 'olcu_tablosu':
      return Icons.straighten;
    case 'renk_karti':
      return Icons.palette;
    default:
      return Icons.insert_drive_file;
  }
}

Color getDosyaColor(String? tip) {
  switch (tip) {
    case 'teknik_cizim':
      return Colors.blue;
    case 'olcu_tablosu':
      return Colors.green;
    case 'renk_karti':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}
