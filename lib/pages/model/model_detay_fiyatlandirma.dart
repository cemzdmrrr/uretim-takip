// ignore_for_file: invalid_use_of_protected_member
part of 'model_detay.dart';

/// Fiyatlandırma (Pricing) tab extension for _ModelDetayState.
extension _FiyatlandirmaTabExt on _ModelDetayState {
  // ==================== FİYATLANDIRMA SEKMESİ (Excel Tarzı) ====================
  
  // Toplam maliyeti hesapla (kar marjı olmadan)
  double _getCurrentTotalCost() {
    double redSum = 0.0;
    
    // İplik maliyeti
    redSum += (currentModelData?['iplik_maliyeti'] ?? 0).toDouble();
    
    // Örgü fiyatı
    redSum += (currentModelData?['orgu_fiyat'] ?? 0).toDouble();
    
    // Diğer maliyetler
    redSum += (currentModelData?['dikim_fiyat'] ?? 0).toDouble();
    redSum += (currentModelData?['utu_fiyat'] ?? 0).toDouble();
    redSum += (currentModelData?['yikama_fiyat'] ?? 0).toDouble();
    redSum += (currentModelData?['ilik_dugme_fiyat'] ?? 0).toDouble();
    redSum += (currentModelData?['fermuar_fiyat'] ?? 0).toDouble();
    redSum += (currentModelData?['aksesuar_fiyat'] ?? 0).toDouble();
    redSum += (currentModelData?['genel_aksesuar_fiyat'] ?? 0).toDouble();
    redSum += (currentModelData?['genel_gider_fiyat'] ?? 0).toDouble();
    
    return redSum;
  }
  
  // Final fiyatı hesapla
  double _calculateFinalPrice() {
    final double redSum = _getCurrentTotalCost();
    
    // Kar marjı
    final karMarjiYuzde = (currentModelData?['kar_marji'] ?? 0).toDouble();
    final double karMarjiCarpan = 1.0 + (karMarjiYuzde / 100.0);
    
    double finalPrice = redSum * karMarjiCarpan;
    
    // Vade hesaplaması
    final vadeAy = (currentModelData?['vade_ay'] ?? 0).toInt();
    if (vadeAy > 0) {
      final vadeOrani = (currentModelData?['vade_orani'] ?? 0).toDouble();
      if (vadeOrani > 0) {
        finalPrice = finalPrice * (1 + vadeOrani / 100);
      }
    }
    
    return finalPrice;
  }
  
  Widget _buildFiyatlandirmaTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.white, Colors.green[50]!],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uyarı kartı
            Card(
              color: Colors.amber[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bu bilgiler sadece admin kullanıcıları tarafından görülebilir ve düzenlenebilir.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Excel Tarzı Fiyatlandırma Tablosu
            _buildExcelStyleTable(),
            
            const SizedBox(height: 24),
            
            // Kar Marjı ve Özet Analizi
            _buildProfitAnalysisCard(),
            
            const SizedBox(height: 24),
            
            // Kaydet Butonu
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveFiyatBilgileri,
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Fiyat Bilgilerini Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcelStyleTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          // Tablo Başlığı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[600]!, Colors.orange[400]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.table_chart, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'MALİYET KALEMLERİ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Model bilgileri
          _buildExcelRow('MODEL', currentModelData?['model_adi'] ?? '-', Colors.blue[50]!, false, Icons.style),
          _buildExcelRow('İP CİNSİ', currentModelData?['iplik_karisimi'] ?? '-', Colors.blue[50]!, false, Icons.texture),
          _buildExcelRow('ÜRÜN GR', 'teknik_gramaj', Colors.white, true, Icons.scale),
          _buildExcelRow('İPLİK KG FİYATI', 'iplik_kg_fiyati', Colors.white, true, Icons.attach_money),
          _buildExcelRow('İPLİK MALİYETİ', 'iplik_maliyeti', Colors.red[100]!, true, Icons.calculate, isCalculated: true, formula: 'ürün gr × iplik kg fiyatı'),
          
          _buildExcelDivider('ÜRETİM MALİYETLERİ'),
          
          _buildExcelRow('MAKİNE ÇIKIŞ SÜRESİ (DK)', 'makina_cikis_suresi', Colors.white, true, Icons.timer),
          _buildExcelRow('MAKİNA DK FİYATI', 'makina_dk_fiyati', Colors.white, true, Icons.precision_manufacturing),
          _buildExcelRow('ÖRGÜ FİYATI', 'orgu_fiyat', Colors.red[100]!, true, Icons.calculate, isCalculated: true, formula: 'makine süresi × dk fiyatı'),
          _buildExcelRow('DİKİM FİYATI', 'dikim_fiyat', Colors.red[100]!, true, Icons.construction),
          _buildExcelRow('ÜTÜ FİYATI', 'utu_fiyat', Colors.red[100]!, true, Icons.iron),
          _buildExcelRow('YIKAMA FİYATI', 'yikama_fiyat', Colors.red[100]!, true, Icons.local_laundry_service),
          
          _buildExcelDivider('AKSESUAR MALİYETLERİ'),
          
          _buildExcelRow('İLİK DÜĞME FİYATI', 'ilik_dugme_fiyat', Colors.red[100]!, true, Icons.radio_button_unchecked),
          _buildExcelRow('FERMUAR FİYATI', 'fermuar_fiyat', Colors.red[100]!, true, Icons.keyboard_double_arrow_up),
          _buildExcelRow('BASKI / NAKIŞ', 'aksesuar_fiyat', Colors.red[100]!, true, Icons.brush),
          _buildExcelRow('GENEL AKSESUAR', 'genel_aksesuar_fiyat', Colors.red[100]!, true, Icons.category),
          
          _buildExcelDivider('GENEL GİDERLER'),
          
          _buildExcelRow('GENEL GİDER', 'genel_gider_fiyat', Colors.red[100]!, true, Icons.business_center),
          
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

  Widget _buildExcelRow(String label, dynamic keyOrValue, Color bgColor, bool isEditable, IconData icon, {bool isCalculated = false, String? formula}) {
    // keyOrValue bir String key ise veritabanından değer al, değilse direkt değer olarak kullan
    final bool isKey = isEditable || isCalculated;
    final String displayValue = isKey 
        ? (currentModelData?[keyOrValue]?.toString() ?? '-')
        : keyOrValue.toString();
    final String key = isKey ? keyOrValue : '';
    
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Icon + Label kısmı
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(right: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
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
                padding: const EdgeInsets.all(12),
                color: bgColor,
                child: isCalculated 
                  ? _buildCalculatedContent(key, formula)
                  : (isEditable && _isEditing)
                    ? _buildEditableContent(key)
                    : _buildReadOnlyContent(displayValue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatedContent(String key, String? formula) {
    final value = currentModelData?[key]?.toString() ?? '0';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[100]!, Colors.green[50]!],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            TextFormField(
              initialValue: value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green[800],
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixText: '₺',
              ),
              onChanged: (newValue) {
                currentModelData?[key] = double.tryParse(newValue) ?? 0;
                setState(() {});
              },
            )
          else
            Row(
              children: [
                Icon(Icons.functions, size: 16, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text(
                  '$value ₺',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          if (formula != null)
            Text(
              formula,
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableContent(String key) {
    final value = currentModelData?[key]?.toString() ?? '';
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.edit, size: 16),
        ),
        onChanged: (newValue) {
          currentModelData?[key] = double.tryParse(newValue) ?? 0;
          setState(() {});
        },
      ),
    );
  }

  Widget _buildReadOnlyContent(String displayValue) {
    final bool isNumeric = double.tryParse(displayValue.replaceAll(',', '.')) != null;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isNumeric ? '$displayValue ₺' : displayValue,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExcelDivider(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[200]!],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.category, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400], indent: 16)),
        ],
      ),
    );
  }

  Widget _buildKarMarjiRow() {
    final karMarji = currentModelData?['kar_marji']?.toString() ?? '0';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[200]!, Colors.green[100]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Icon + Label kısmı
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[300]!, Colors.green[200]!],
                  ),
                  border: Border(right: BorderSide(color: Colors.green[300]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.trending_up, size: 18, color: Colors.green[700]),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'KAR MARJI (%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
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
                padding: const EdgeInsets.all(12),
                child: _isEditing
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        initialValue: karMarji,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.green[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixText: '%',
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          prefixIcon: const Icon(Icons.percent, color: Colors.green),
                        ),
                        onChanged: (value) {
                          currentModelData?['kar_marji'] = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                          setState(() {});
                        },
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '%$karMarji',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVadeRow() {
    final vadeAy = (currentModelData?['vade_ay'] ?? 0).toInt();
    final vadeOrani = currentModelData?['vade_orani']?.toString() ?? '0';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[200]!, Colors.amber[100]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Column(
        children: [
          // Vade seçimi
          IntrinsicHeight(
            child: Row(
              children: [
                // Icon + Label kısmı
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[300]!, Colors.amber[200]!],
                      ),
                      border: Border(right: BorderSide(color: Colors.orange[300]!)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_month, size: 18, color: Colors.orange[700]),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'VADE SEÇENEĞİ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Vade seçimi
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: _isEditing
                      ? DropdownButtonFormField<int>(
                          initialValue: vadeAy,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.orange[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
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
                            setState(() {
                              currentModelData?['vade_ay'] = value ?? 0;
                            });
                          },
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vadeAy == 0 ? 'PEŞİN' : '$vadeAy AY VADE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
          
          // Vade oranı (sadece vade seçildiyse)
          if (vadeAy > 0)
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[300]!, Colors.orange[200]!],
                        ),
                        border: Border(right: BorderSide(color: Colors.amber[300]!)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.percent, size: 18, color: Colors.amber[700]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'VADE ORANI ($vadeAy AY)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
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
                      padding: const EdgeInsets.all(12),
                      child: _isEditing
                        ? TextFormField(
                            initialValue: vadeOrani,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber[300]!),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixText: '%',
                              hintText: 'örn: 10',
                            ),
                            onChanged: (value) {
                              currentModelData?['vade_orani'] = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                              setState(() {});
                            },
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '%$vadeOrani',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinalPriceRow() {
    final vadeAy = (currentModelData?['vade_ay'] ?? 0).toInt();
    final finalPrice = _calculateFinalPrice();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.indigo[700]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vadeAy == 0 ? 'PEŞİN FİYAT' : '$vadeAy AY VADELİ FİYAT',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${finalPrice.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'FİNAL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitAnalysisCard() {
    final redSum = _getCurrentTotalCost();
    final karMarjiYuzde = (currentModelData?['kar_marji'] ?? 0).toDouble();
    final vadeAy = (currentModelData?['vade_ay'] ?? 0).toInt();
    final finalPrice = _calculateFinalPrice();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modern Başlık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[600]!, Colors.indigo[600]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'HESAPLAMA ANALİZİ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // İçerik
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Hesaplama mantığı
                _buildCalculationMethodCard(),
                
                const SizedBox(height: 20),
                
                // Sonuç kartları
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildResultCard('TOPLAM MALİYET', '${redSum.toStringAsFixed(2)} ₺', Icons.calculate, Colors.red),
                    _buildResultCard('KAR MARJI', '%${karMarjiYuzde.toInt()}', Icons.trending_up, Colors.green),
                    _buildResultCard('VADE', vadeAy == 0 ? 'PEŞİN' : '$vadeAy AY', Icons.schedule, Colors.orange),
                    _buildResultCard('FINAL FİYAT', '${finalPrice.toStringAsFixed(2)} ₺', Icons.monetization_on, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationMethodCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'HESAPLAMA FORMÜLÜ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFormulaStep('🔴', 'Kırmızı Alanlar', 'TOPLANIR', Colors.red[100]!),
              Icon(Icons.close, color: Colors.grey[600]),
              _buildFormulaStep('🟢', 'Kar Marjı', 'ÇARPILIR', Colors.green[100]!),
              Icon(Icons.arrow_forward, color: Colors.grey[600]),
              _buildFormulaStep('💰', 'Final Fiyat', 'SONUÇ', Colors.blue[100]!),
            ],
          ),
          
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Formül: (Tüm Kırmızı Maliyetler) × (1 + Kar Marjı/100)',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaStep(String emoji, String title, String action, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            action,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[100]!, color[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color[700], size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _saveFiyatBilgileri() async {
    setState(() => _isSaving = true);
    
    try {
      await supabase
          .from(DbTables.trikoTakip)
          .update(currentModelData!)
          .eq('id', widget.modelId);
      
      if (!mounted) return;
      context.showSuccessSnackBar('✅ Fiyat bilgileri başarıyla güncellendi');
      
      setState(() {
        _isSaving = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
      setState(() => _isSaving = false);
    }
  }
}
