// ignore_for_file: invalid_use_of_protected_member
part of 'model_detay.dart';

/// Fiyatlandırma (Pricing) tab extension for _ModelDetayState.
extension _FiyatlandirmaTabExt on _ModelDetayState {
  // ==================== FİYATLANDIRMA SEKMESİ (Excel Tarzı) ====================

  static const List<String> _fiyatMaliyetAlanlari = [
    'dikim_fiyat',
    'utu_fiyat',
    'yikama_fiyat',
    'ilik_dugme_fiyat',
    'fermuar_fiyat',
    'aksesuar_fiyat',
    'genel_aksesuar_fiyat',
    'genel_gider_fiyat',
  ];

  double _fiyatDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    final raw = value.toString().trim();
    if (raw.isEmpty) return 0;

    final cleaned = raw.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (cleaned.isEmpty || cleaned == '-' || cleaned == ',' || cleaned == '.') {
      return 0;
    }

    if (cleaned.contains(',') && cleaned.contains('.')) {
      return double.tryParse(
              cleaned.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }

    if (cleaned.contains(',')) {
      return double.tryParse(cleaned.replaceAll(',', '.')) ?? 0;
    }

    final isThousandsOnly =
        RegExp(r'^-?[0-9]{1,3}(\.[0-9]{3})+$').hasMatch(cleaned);
    if (isThousandsOnly) {
      return double.tryParse(cleaned.replaceAll('.', '')) ?? 0;
    }

    return double.tryParse(cleaned) ?? 0;
  }

  int _fiyatInt(dynamic value) => _fiyatDouble(value).round();

  String _formatPara(double value) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
        .format(value);
  }

  String _formatSayi(double value, {int decimalDigits = 2}) {
    final formatter = NumberFormat.decimalPattern('tr_TR')
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(value);
  }

  bool _isFiyatSayisi(String value) {
    final text = value.replaceAll('₺', '').trim();
    if (text.isEmpty) return false;

    return RegExp(r'^-?\d+([,.]\d+)?$').hasMatch(text) ||
        RegExp(r'^-?\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(text) ||
        RegExp(r'^-?\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(text);
  }

  double _hesaplananIplikMaliyeti() {
    final gramaj = _fiyatDouble(currentModelData?['teknik_gramaj']);
    final kgFiyati = _fiyatDouble(currentModelData?['iplik_kg_fiyati']);

    if (gramaj > 0 && kgFiyati > 0) {
      return gramaj * kgFiyati;
    }

    return _fiyatDouble(currentModelData?['iplik_maliyeti']);
  }

  double _hesaplananOrguFiyati() {
    final makineSuresi = _fiyatDouble(currentModelData?['makina_cikis_suresi']);
    final dakikaFiyati = _fiyatDouble(currentModelData?['makina_dk_fiyati']);

    if (makineSuresi > 0 && dakikaFiyati > 0) {
      return makineSuresi * dakikaFiyati;
    }

    return _fiyatDouble(currentModelData?['orgu_fiyat']);
  }

  double _hesaplananDeger(String key) {
    return switch (key) {
      'iplik_maliyeti' => _hesaplananIplikMaliyeti(),
      'orgu_fiyat' => _hesaplananOrguFiyati(),
      _ => _fiyatDouble(currentModelData?[key]),
    };
  }

  void _fiyatModeliniYazilabilirYap() {
    final data = currentModelData;
    if (data == null) return;
    currentModelData = Map<String, dynamic>.from(data);
  }

  void _hesaplananMaliyetleriGuncelle() {
    if (currentModelData == null) return;
    _fiyatModeliniYazilabilirYap();
    currentModelData!['iplik_maliyeti'] = _hesaplananIplikMaliyeti();
    currentModelData!['orgu_fiyat'] = _hesaplananOrguFiyati();
  }

  void _setFiyatAlani(String key, dynamic value) {
    if (currentModelData == null) return;
    _updateState(() {
      _fiyatModeliniYazilabilirYap();
      currentModelData![key] = _fiyatDouble(value);
      _hesaplananMaliyetleriGuncelle();
    });
  }

  // Toplam maliyeti hesapla (kar marjı olmadan)
  double _getCurrentTotalCost() {
    return _hesaplananIplikMaliyeti() +
        _hesaplananOrguFiyati() +
        _fiyatMaliyetAlanlari.fold<double>(
          0,
          (sum, key) => sum + _fiyatDouble(currentModelData?[key]),
        );
  }

  // Final fiyatı hesapla
  double _calculateFinalPrice() {
    final double redSum = _getCurrentTotalCost();

    // Kar marjı
    final karMarjiYuzde = _fiyatDouble(currentModelData?['kar_marji']);
    final double karMarjiCarpan = 1.0 + (karMarjiYuzde / 100.0);

    double finalPrice = redSum * karMarjiCarpan;

    // Vade hesaplaması
    final vadeAy = _fiyatInt(currentModelData?['vade_ay']);
    if (vadeAy > 0) {
      final vadeOrani = _fiyatDouble(currentModelData?['vade_orani']);
      if (vadeOrani > 0) {
        finalPrice = finalPrice * (1 + vadeOrani / 100);
      }
    }

    return finalPrice;
  }

  Widget _buildFiyatlandirmaTab() {
    return Container(
      color: const Color(0xFFF4F7FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1180;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPricingHeader(),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildExcelStyleTable()),
                      const SizedBox(width: 12),
                      SizedBox(width: 380, child: _buildProfitAnalysisCard()),
                    ],
                  )
                else ...[
                  _buildExcelStyleTable(),
                  const SizedBox(height: 12),
                  _buildProfitAnalysisCard(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPricingHeader() {
    final maliyet = _getCurrentTotalCost();
    final finalFiyat = _calculateFinalPrice();
    final karOrani = _fiyatDouble(currentModelData?['kar_marji']);
    final vadeAy = _fiyatInt(currentModelData?['vade_ay']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE5EE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.price_change, color: Color(0xFF1F5F8B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fiyatlandırma Kartı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2742),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${currentModelData?['model_adi'] ?? '-'} · ${currentModelData?['marka'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF607D8B),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEditing)
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveFiyatBilgileri,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isSaving ? 'Kaydediliyor' : 'Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5F8B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, metricConstraints) {
              final columns = metricConstraints.maxWidth < 760 ? 2 : 4;
              final itemWidth =
                  (metricConstraints.maxWidth - ((columns - 1) * 8)) / columns;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildPricingMetric(
                      'Toplam Maliyet',
                      _formatPara(maliyet),
                      Icons.calculate,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildPricingMetric(
                      'Kar Oranı',
                      '%${_formatSayi(karOrani, decimalDigits: 1)}',
                      Icons.trending_up,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildPricingMetric(
                      'Vade',
                      vadeAy == 0 ? 'Peşin' : '$vadeAy Ay',
                      Icons.event,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildPricingMetric(
                      'Satış Fiyatı',
                      _formatPara(finalFiyat),
                      Icons.sell,
                      emphasized: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingMetric(
    String label,
    String value,
    IconData icon, {
    bool emphasized = false,
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFEAF5EF) : const Color(0xFFF7FAFD),
        border: Border.all(
          color: emphasized ? const Color(0xFFBFDCCB) : const Color(0xFFE1E8F0),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                emphasized ? const Color(0xFF2E7D32) : const Color(0xFF607D8B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF607D8B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: emphasized ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: emphasized
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF0F2742),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelStyleTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5EE), width: 1),
      ),
      child: Column(
        children: [
          // Tablo Başlığı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF3F8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFDDE5EE)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.table_chart, color: Color(0xFF456579), size: 20),
                SizedBox(width: 10),
                Text(
                  'MALİYET KALEMLERİ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F2742),
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                Text(
                  'Kaynak / Değer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF607D8B),
                  ),
                ),
              ],
            ),
          ),

          // Model bilgileri
          _buildExcelRow('MODEL', currentModelData?['model_adi'] ?? '-',
              Colors.blue[50]!, false, Icons.style),
          _buildExcelRow('İP CİNSİ', currentModelData?['iplik_karisimi'] ?? '-',
              Colors.blue[50]!, false, Icons.texture),
          _buildExcelRow(
              'ÜRÜN GR', 'teknik_gramaj', Colors.white, true, Icons.scale),
          _buildExcelRow('İPLİK KG FİYATI', 'iplik_kg_fiyati', Colors.white,
              true, Icons.attach_money),
          _buildExcelRow('İPLİK MALİYETİ', 'iplik_maliyeti', Colors.red[100]!,
              true, Icons.calculate,
              isCalculated: true, formula: 'ürün gr × iplik kg fiyatı'),

          _buildExcelDivider('ÜRETİM MALİYETLERİ'),

          _buildExcelRow('MAKİNE ÇIKIŞ SÜRESİ (DK)', 'makina_cikis_suresi',
              Colors.white, true, Icons.timer),
          _buildExcelRow('MAKİNA DK FİYATI', 'makina_dk_fiyati', Colors.white,
              true, Icons.precision_manufacturing),
          _buildExcelRow('ÖRGÜ FİYATI', 'orgu_fiyat', Colors.red[100]!, true,
              Icons.calculate,
              isCalculated: true, formula: 'makine süresi × dk fiyatı'),
          _buildExcelRow('DİKİM FİYATI', 'dikim_fiyat', Colors.red[100]!, true,
              Icons.construction),
          _buildExcelRow(
              'ÜTÜ FİYATI', 'utu_fiyat', Colors.red[100]!, true, Icons.iron),
          _buildExcelRow('YIKAMA FİYATI', 'yikama_fiyat', Colors.red[100]!,
              true, Icons.local_laundry_service),

          _buildExcelDivider('AKSESUAR MALİYETLERİ'),

          _buildExcelRow('İLİK DÜĞME FİYATI', 'ilik_dugme_fiyat',
              Colors.red[100]!, true, Icons.radio_button_unchecked),
          _buildExcelRow('FERMUAR FİYATI', 'fermuar_fiyat', Colors.red[100]!,
              true, Icons.keyboard_double_arrow_up),
          _buildExcelRow('BASKI / NAKIŞ', 'aksesuar_fiyat', Colors.red[100]!,
              true, Icons.brush),
          _buildExcelRow('GENEL AKSESUAR', 'genel_aksesuar_fiyat',
              Colors.red[100]!, true, Icons.category),

          _buildExcelDivider('GENEL GİDERLER'),

          _buildExcelRow('GENEL GİDER', 'genel_gider_fiyat', Colors.red[100]!,
              true, Icons.business_center),

          // Kar marjı
          _buildKarMarjiRow(),

          // Vade seçenekleri
          _buildVadeRow(),

          // Final fiyat
          _buildFinalPriceRow(),
        ],
      ),
    );
  }

  Widget _buildExcelRow(String label, dynamic keyOrValue, Color bgColor,
      bool isEditable, IconData icon,
      {bool isCalculated = false, String? formula}) {
    // keyOrValue bir String key ise veritabanından değer al, değilse direkt değer olarak kullan
    final bool isKey = isEditable || isCalculated;
    final String displayValue = isKey
        ? (currentModelData?[keyOrValue]?.toString() ?? '-')
        : keyOrValue.toString();
    final String key = isKey ? keyOrValue : '';
    final rowAccent =
        isCalculated ? const Color(0xFF2E7D32) : const Color(0xFF607D8B);
    final valueBg =
        isCalculated ? const Color(0xFFF3FAF5) : const Color(0xFFFFFFFF);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6EDF3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Icon + Label kısmı
          Expanded(
            flex: 3,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFCFE),
                border: Border(
                  right: BorderSide(color: Color(0xFFE6EDF3)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: rowAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 17, color: rowAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF243746),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Değer kısmı
          Expanded(
            flex: 2,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              color: valueBg,
              child: isCalculated
                  ? _buildCalculatedContent(key, formula)
                  : (isEditable && _isEditing)
                      ? _buildEditableContent(key)
                      : _buildReadOnlyContent(displayValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatedContent(String key, String? formula) {
    final value = _hesaplananDeger(key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCFE6D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatPara(value),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          if (formula != null) ...[
            const SizedBox(height: 3),
            Text(
              formula,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF607D8B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableContent(String key) {
    final value = currentModelData?[key]?.toString() ?? '';

    return TextFormField(
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F2742),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDDE5EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDDE5EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF1F5F8B), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (newValue) {
        _setFiyatAlani(key, newValue);
      },
    );
  }

  Widget _buildReadOnlyContent(String displayValue) {
    final value = _fiyatDouble(displayValue);
    final bool isNumeric = _isFiyatSayisi(displayValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Text(
        isNumeric ? _formatPara(value) : displayValue,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF243746),
        ),
      ),
    );
  }

  Widget _buildExcelDivider(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6EDF3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open, size: 16, color: Color(0xFF607D8B)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF456579),
              letterSpacing: 0.5,
            ),
          ),
          const Expanded(
            child: Divider(color: Color(0xFFDDE5EE), indent: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildKarMarjiRow() {
    final karMarji = _formatSayi(_fiyatDouble(currentModelData?['kar_marji']));

    return _buildErpControlRow(
      label: 'KAR ORANI (%)',
      icon: Icons.trending_up,
      child: _isEditing
          ? TextFormField(
              initialValue: karMarji,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F2742),
              ),
              decoration: _erpInputDecoration(suffixText: '%'),
              onChanged: (value) => _setFiyatAlani('kar_marji', value),
            )
          : _buildStaticValue('%$karMarji'),
    );
  }

  InputDecoration _erpInputDecoration({String? suffixText}) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFDDE5EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFDDE5EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF1F5F8B), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixText: suffixText,
    );
  }

  Widget _buildStaticValue(String value, {bool strong = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        border: Border.all(color: const Color(0xFFE6EDF3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: strong ? 16 : 13,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          color: strong ? const Color(0xFF1B5E20) : const Color(0xFF243746),
        ),
      ),
    );
  }

  Widget _buildErpControlRow({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6EDF3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFCFE),
                border: Border(
                  right: BorderSide(color: Color(0xFFE6EDF3)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF607D8B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 17, color: const Color(0xFF607D8B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF243746),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVadeRow() {
    final vadeAy = _fiyatInt(currentModelData?['vade_ay']);
    final vadeOrani =
        _formatSayi(_fiyatDouble(currentModelData?['vade_orani']));

    return Column(
      children: [
        _buildErpControlRow(
          label: 'VADE SEÇENEĞİ',
          icon: Icons.calendar_month,
          child: _isEditing
              ? DropdownButtonFormField<int>(
                  initialValue: vadeAy,
                  decoration: _erpInputDecoration(),
                  items: const [
                    DropdownMenuItem<int>(value: 0, child: Text('PEŞİN')),
                    DropdownMenuItem<int>(value: 1, child: Text('1 AY')),
                    DropdownMenuItem<int>(value: 2, child: Text('2 AY')),
                    DropdownMenuItem<int>(value: 3, child: Text('3 AY')),
                    DropdownMenuItem<int>(value: 4, child: Text('4 AY')),
                    DropdownMenuItem<int>(value: 5, child: Text('5 AY')),
                    DropdownMenuItem<int>(value: 6, child: Text('6 AY')),
                  ],
                  onChanged: (value) {
                    _updateState(() {
                      currentModelData?['vade_ay'] = value ?? 0;
                    });
                  },
                )
              : _buildStaticValue(vadeAy == 0 ? 'PEŞİN' : '$vadeAy AY VADE'),
        ),
        if (vadeAy > 0)
          _buildErpControlRow(
            label: 'VADE ORANI ($vadeAy AY)',
            icon: Icons.percent,
            child: _isEditing
                ? TextFormField(
                    initialValue: vadeOrani,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F2742),
                    ),
                    decoration: _erpInputDecoration(suffixText: '%'),
                    onChanged: (value) => _setFiyatAlani('vade_orani', value),
                  )
                : _buildStaticValue('%$vadeOrani'),
          ),
      ],
    );
  }

  Widget _buildFinalPriceRow() {
    final vadeAy = _fiyatInt(currentModelData?['vade_ay']);
    final finalPrice = _calculateFinalPrice();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEAF5EF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFCFE6D5)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.sell,
                      size: 17,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      vadeAy == 0
                          ? 'PEŞİN SATIŞ FİYATI'
                          : '$vadeAy AY VADELİ SATIŞ FİYATI',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              alignment: Alignment.centerLeft,
              child: _buildStaticValue(_formatPara(finalPrice), strong: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitAnalysisCard() {
    final redSum = _getCurrentTotalCost();
    final karMarjiYuzde = _fiyatDouble(currentModelData?['kar_marji']);
    final vadeAy = _fiyatInt(currentModelData?['vade_ay']);
    final finalPrice = _calculateFinalPrice();
    final karTutar = finalPrice - redSum;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF3F8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFDDE5EE)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFF456579), size: 20),
                SizedBox(width: 10),
                Text(
                  'KARAR ÖZETİ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F2742),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDecisionLine(
                  'Toplam maliyet',
                  _formatPara(redSum),
                  Icons.calculate,
                ),
                _buildDecisionLine(
                  'Kar oranı',
                  '%${_formatSayi(karMarjiYuzde, decimalDigits: 1)}',
                  Icons.trending_up,
                ),
                _buildDecisionLine(
                  'Kar tutarı',
                  _formatPara(karTutar),
                  Icons.account_balance_wallet,
                ),
                _buildDecisionLine(
                  'Vade',
                  vadeAy == 0 ? 'Peşin' : '$vadeAy Ay',
                  Icons.event,
                ),
                const Divider(height: 24, color: Color(0xFFE6EDF3)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDCCB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Satış Fiyatı',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF607D8B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPara(finalPrice),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCalculationMethodCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionLine(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF607D8B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF607D8B),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F2742),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions, color: Color(0xFF456579), size: 18),
              SizedBox(width: 8),
              Text(
                'Hesaplama',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F2742),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Satış fiyatı = Toplam maliyet x (1 + kar oranı / 100). Vade seçilirse vade oranı ayrıca uygulanır.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF607D8B),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildFiyatlandirmaPayload() {
    _hesaplananMaliyetleriGuncelle();

    final payload = <String, dynamic>{
      'teknik_gramaj': _fiyatDouble(currentModelData?['teknik_gramaj']),
      'iplik_kg_fiyati': _fiyatDouble(currentModelData?['iplik_kg_fiyati']),
      'iplik_maliyeti': _hesaplananIplikMaliyeti(),
      'makina_cikis_suresi':
          _fiyatDouble(currentModelData?['makina_cikis_suresi']),
      'makina_dk_fiyati': _fiyatDouble(currentModelData?['makina_dk_fiyati']),
      'orgu_fiyat': _hesaplananOrguFiyati(),
      'dikim_fiyat': _fiyatDouble(currentModelData?['dikim_fiyat']),
      'utu_fiyat': _fiyatDouble(currentModelData?['utu_fiyat']),
      'yikama_fiyat': _fiyatDouble(currentModelData?['yikama_fiyat']),
      'ilik_dugme_fiyat': _fiyatDouble(currentModelData?['ilik_dugme_fiyat']),
      'fermuar_fiyat': _fiyatDouble(currentModelData?['fermuar_fiyat']),
      'aksesuar_fiyat': _fiyatDouble(currentModelData?['aksesuar_fiyat']),
      'genel_aksesuar_fiyat':
          _fiyatDouble(currentModelData?['genel_aksesuar_fiyat']),
      'genel_gider_fiyat': _fiyatDouble(currentModelData?['genel_gider_fiyat']),
      'kar_marji': _fiyatDouble(currentModelData?['kar_marji']),
      'vade_ay': _fiyatInt(currentModelData?['vade_ay']),
      'vade_orani': _fiyatDouble(currentModelData?['vade_orani']),
      'pesin_fiyat': _calculateFinalPrice(),
    };

    for (final column in [
      'satis_fiyati',
      'final_fiyat',
      'birim_satis_fiyati'
    ]) {
      if (currentModelData?.containsKey(column) ?? false) {
        payload[column] = _calculateFinalPrice();
      }
    }

    if (currentModelData?.containsKey('updated_at') ?? false) {
      payload['updated_at'] = DateTime.now().toIso8601String();
    }

    return payload;
  }

  Future<void> _saveFiyatBilgileri() async {
    if (currentModelData == null) return;

    _updateState(() => _isSaving = true);

    try {
      final payload = _buildFiyatlandirmaPayload();
      final updatedRows = await supabase
          .from(DbTables.trikoTakip)
          .update(payload)
          .eq('id', widget.modelId)
          .select()
          .limit(1);

      if (updatedRows.isNotEmpty) {
        currentModelData = Map<String, dynamic>.from(updatedRows.first as Map);
      } else {
        currentModelData?.addAll(payload);
      }

      try {
        await supabase.rpc(
          'model_karlilik_ozeti_yenile',
          params: {'p_model_id': widget.modelId},
        );
        await _maliyetVerileriniGetir();
      } catch (e) {
        debugPrint('Karlılık özeti yenilenemedi: $e');
      }

      if (!mounted) return;
      context.showSuccessSnackBar('Fiyat bilgileri başarıyla güncellendi');

      _updateState(() {
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
      _updateState(() => _isSaving = false);
    }
  }
}
