import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Tekstil dalına özgü dinamik form alanı tanımı
class FormAlan {
  final String kod;
  final String ad;
  final FormAlanTipi tip;
  final List<String>? secenekler;
  final String? varsayilanDeger;
  final bool zorunlu;
  final int siraNo;
  final String? grup;

  const FormAlan({
    required this.kod,
    required this.ad,
    this.tip = FormAlanTipi.text,
    this.secenekler,
    this.varsayilanDeger,
    this.zorunlu = false,
    this.siraNo = 0,
    this.grup,
  });

  factory FormAlan.fromJson(Map<String, dynamic> json) {
    List<String>? secenekler;
    if (json['secenekler'] != null) {
      if (json['secenekler'] is String) {
        secenekler = List<String>.from(jsonDecode(json['secenekler']));
      } else if (json['secenekler'] is List) {
        secenekler = List<String>.from(json['secenekler']);
      }
    }

    return FormAlan(
      kod: json['alan_kodu'] as String,
      ad: json['alan_adi'] as String,
      tip: FormAlanTipi.fromString(json['alan_tipi'] as String? ?? 'text'),
      secenekler: secenekler,
      varsayilanDeger: json['varsayilan_deger'] as String?,
      zorunlu: json['zorunlu'] as bool? ?? false,
      siraNo: json['sira_no'] as int? ?? 0,
      grup: json['grup'] as String?,
    );
  }
}

enum FormAlanTipi {
  text,
  number,
  dropdown,
  checkbox,
  date,
  textarea,
  color;

  static FormAlanTipi fromString(String s) {
    return FormAlanTipi.values.firstWhere(
      (e) => e.name == s,
      orElse: () => FormAlanTipi.text,
    );
  }
}

/// Dal bazlı form alanları servisi — DB'den yükler, bellekte cache'ler
class DalFormAlanlariService {
  static final Map<String, List<FormAlan>> _cache = {};

  /// Belirtilen tekstil dalının form alanlarını getirir
  static Future<List<FormAlan>> alanlariGetir(String tekstilDali) async {
    if (_cache.containsKey(tekstilDali)) return _cache[tekstilDali]!;

    final response = await Supabase.instance.client
        .from('dal_form_alanlari')
        .select()
        .eq('tekstil_dali', tekstilDali)
        .eq('aktif', true)
        .order('sira_no');

    final alanlar = (response as List)
        .map((e) => FormAlan.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache[tekstilDali] = alanlar;
    return alanlar;
  }

  /// Gruplarına göre alanları döndürür
  static Future<Map<String, List<FormAlan>>> gruplariGetir(
      String tekstilDali) async {
    final alanlar = await alanlariGetir(tekstilDali);
    final Map<String, List<FormAlan>> gruplar = {};
    for (final alan in alanlar) {
      final g = alan.grup ?? 'Genel';
      gruplar.putIfAbsent(g, () => []).add(alan);
    }
    return gruplar;
  }

  /// Cache temizle (dal değişikliğinde)
  static void cacheTemizle([String? tekstilDali]) {
    if (tekstilDali != null) {
      _cache.remove(tekstilDali);
    } else {
      _cache.clear();
    }
  }
}

/// Dinamik form alanı widget'ı — FormAlan tanımına göre uygun widget üretir
class DalOzelAlanWidget extends StatelessWidget {
  final FormAlan alan;
  final dynamic deger;
  final ValueChanged<dynamic> onChanged;

  const DalOzelAlanWidget({
    super.key,
    required this.alan,
    this.deger,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (alan.tip) {
      case FormAlanTipi.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: deger as String?,
          decoration: InputDecoration(
            labelText: alan.ad,
            border: const OutlineInputBorder(),
          ),
          items: (alan.secenekler ?? [])
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
          validator: alan.zorunlu ? (v) => v == null ? '${alan.ad} seçiniz' : null : null,
        );

      case FormAlanTipi.number:
        return TextFormField(
          initialValue: deger?.toString(),
          decoration: InputDecoration(
            labelText: alan.ad,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(num.tryParse(v)),
          validator: alan.zorunlu
              ? (v) => (v == null || v.isEmpty) ? '${alan.ad} giriniz' : null
              : null,
        );

      case FormAlanTipi.checkbox:
        return CheckboxListTile(
          title: Text(alan.ad),
          value: deger == true,
          onChanged: (v) => onChanged(v),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );

      case FormAlanTipi.textarea:
        return TextFormField(
          initialValue: deger as String?,
          decoration: InputDecoration(
            labelText: alan.ad,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: onChanged,
          validator: alan.zorunlu
              ? (v) => (v == null || v.isEmpty) ? '${alan.ad} giriniz' : null
              : null,
        );

      case FormAlanTipi.date:
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: deger is DateTime
                  ? deger as DateTime
                  : DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: alan.ad,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              deger is DateTime
                  ? '${(deger as DateTime).day}/${(deger as DateTime).month}/${(deger as DateTime).year}'
                  : (deger?.toString() ?? 'Tarih seçiniz'),
            ),
          ),
        );

      default: // text
        return TextFormField(
          initialValue: deger as String?,
          decoration: InputDecoration(
            labelText: alan.ad,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
          validator: alan.zorunlu
              ? (v) => (v == null || v.isEmpty) ? '${alan.ad} giriniz' : null
              : null,
        );
    }
  }
}
