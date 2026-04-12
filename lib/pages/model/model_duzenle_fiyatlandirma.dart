// ignore_for_file: invalid_use_of_protected_member
part of 'model_duzenle.dart';

/// Model düzenleme - fiyatlandırma formu
extension _FiyatlandirmaDuzenleExt on _ModelDuzenlePageState {
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
            _buildExcelStyleTable(),
            const SizedBox(height: 24),
            _buildProfitAnalysisCard(),
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
            child: Row(
              children: [
                const Icon(Icons.table_chart, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'MALİYET KALEMLERİ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),

          _buildModernExcelRow('MODEL', _modelAdiController.text.isEmpty ? 'Model bilgileri bölümündeki model kodu alınır' : _modelAdiController.text, Colors.blue[50]!, false, Icons.style),
          _buildModernExcelRow('İP CİNSİ', _iplikKarisimiController.text.isEmpty ? 'Model bilgilerindeki iplik karışımından alınır' : _iplikKarisimiController.text, Colors.blue[50]!, false, Icons.texture),
          _buildModernExcelRow('ÜRÜN GR', _gramajController, Colors.white, true, Icons.scale),
          _buildModernExcelRow('İPLİK KG FİYATI', _iplikKgFiyatiController, Colors.white, true, Icons.attach_money),
          _buildModernExcelRow('İPLİK MALİYETİ', _iplikMaliyetiController, Colors.red[100]!, false, Icons.calculate, isCalculated: true, formula: 'ürün gr × iplik kg fiyatı'),

          _buildDivider('ÜRETİM MALİYETLERİ'),

          _buildModernExcelRow('MAKİNE ÇIKIŞ SÜRESİ (DK)', _makinaFiyatController, Colors.white, true, Icons.timer),
          _buildModernExcelRow('MAKİNA DK FİYATI', _makinaDkFiyatiController, Colors.white, true, Icons.precision_manufacturing),
          _buildModernExcelRow('ÖRGÜ FİYATI', _orguFiyatController, Colors.red[100]!, false, Icons.calculate, isCalculated: true, formula: 'makine süresi × dk fiyatı'),
          _buildModernExcelRow('DİKİM FİYATI', _dikimFiyatController, Colors.red[100]!, true, Icons.construction),
          _buildModernExcelRow('ÜTÜ FİYATI', _utuFiyatController, Colors.red[100]!, true, Icons.iron),
          _buildModernExcelRow('YIKAMA FİYATI', _yikamaFiyatController, Colors.red[100]!, true, Icons.local_laundry_service),

          _buildDivider('AKSESUAR MALİYETLERİ'),

          _buildModernExcelRow('İLİK DÜĞME FİYATI', _ilikDugmeFiyatController, Colors.red[100]!, true, Icons.radio_button_unchecked),
          _buildModernExcelRow('FERMUAR FİYATI', _fermuarFiyatController, Colors.red[100]!, true, Icons.keyboard_double_arrow_up),
          _buildModernExcelRow('BASKI / NAKIŞ', _aksesuarFiyatController, Colors.red[100]!, true, Icons.brush),
          _buildModernExcelRow('GENEL AKSESUAR', _genelAksesuarFiyatController, Colors.red[100]!, true, Icons.category),

          _buildDivider('GENEL GİDERLER'),

          _buildModernExcelRow('GENEL GİDER', _genelGiderFiyatController, Colors.red[100]!, true, Icons.business_center),

          _buildModernKarMarjiRow(),
          _buildVadeSecenekleriRow(),
          _buildModernFinalPriceRow(),
        ],
      ),
    );
  }

  Widget _buildModernExcelRow(String label, dynamic controller, Color bgColor, bool isEditable, IconData icon, {bool isCalculated = false, String? formula}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
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
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: bgColor,
                child: isCalculated
                    ? _buildModernCalculatedContent(label, formula)
                    : _buildModernInputContent(controller, isEditable, bgColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(String title) {
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

  Widget _buildModernInputContent(dynamic controller, bool isEditable, Color bgColor) {
    if (controller is String) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Text(
          controller,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[700],
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (!isEditable) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          (controller as TextEditingController).text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

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
        controller: controller as TextEditingController,
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
        onChanged: (value) => _calculateFinalPrice(),
      ),
    );
  }

  Widget _buildModernCalculatedContent(String label, String? formula) {
    String value = '';

    switch (label) {
      case 'İPLİK MALİYETİ':
        final kgFiyat = _parseDouble(_iplikKgFiyatiController.text) ?? 0.0;
        final gramaj = _parseDouble(_gramajController.text) ?? 0.0;
        value = (kgFiyat * gramaj).toStringAsFixed(2);
        _iplikMaliyetiController.text = value;
        break;
      case 'ÖRGÜ FİYATI':
        final makineSure = _parseDouble(_makinaFiyatController.text) ?? 0.0;
        final makineDkFiyati = _parseDouble(_makinaDkFiyatiController.text) ?? 0.0;
        value = (makineSure * makineDkFiyati).toStringAsFixed(2);
        _orguFiyatController.text = value;
        break;
      case 'FİYAT':
        value = _calculateFinalPrice().toStringAsFixed(2);
        _pesinFiyatController.text = value;
        break;
      default:
        value = formula ?? '';
    }

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
          if (value.isNotEmpty && value != formula)
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

  Widget _buildModernKarMarjiRow() {
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
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Container(
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
                    controller: _karMarjiController,
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
                    onChanged: (value) => _calculateFinalPrice(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVadeSecenekleriRow() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[200]!, Colors.amber[100]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
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
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Container(
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
                      child: DropdownButtonFormField<int>(
                        value: _selectedVade,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.orange[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.orange, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.schedule, color: Colors.orange),
                        ),
                        items: const [
                          DropdownMenuItem<int>(value: 0, child: Text('PEŞİN')),
                          DropdownMenuItem<int>(value: 1, child: Text('1 AY VADE')),
                          DropdownMenuItem<int>(value: 2, child: Text('2 AY VADE')),
                          DropdownMenuItem<int>(value: 3, child: Text('3 AY VADE')),
                          DropdownMenuItem<int>(value: 4, child: Text('4 AY VADE')),
                          DropdownMenuItem<int>(value: 5, child: Text('5 AY VADE')),
                          DropdownMenuItem<int>(value: 6, child: Text('6 AY VADE')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedVade = value ?? 0;
                            _calculateFinalPrice();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedVade > 0)
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
                              'VADE ORANI ($_selectedVade AY)',
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
                      child: Container(
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
                          controller: _vadeOraniController,
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.orange, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixText: '%',
                            suffixStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            hintText: 'örn: 10',
                            prefixIcon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                          ),
                          onChanged: (value) => _calculateFinalPrice(),
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

  Widget _buildModernFinalPriceRow() {
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
                    _selectedVade == 0 ? 'PEŞİN FİYAT' : '$_selectedVade AY VADELİ FİYAT',
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
    final karMarjiYuzde = _parseDouble(_karMarjiController.text) ?? 0.0;
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildCalculationMethodCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildResultCard('TOPLAM MALİYET', '${redSum.toStringAsFixed(2)} ₺', Icons.calculate, Colors.red)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildResultCard('KAR MARJI', '%${karMarjiYuzde.toInt()}', Icons.trending_up, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildResultCard('VADE', _selectedVade == 0 ? 'PEŞİN' : '$_selectedVade AY', Icons.schedule, Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildResultCard('FINAL FİYAT', '${finalPrice.toStringAsFixed(2)} ₺', Icons.monetization_on, Colors.blue)),
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
          Row(
            children: [
              _buildFormulaStep('🔴', 'Kırmızı Alanlar', 'TOPLANIR', Colors.red[100]!),
              const SizedBox(width: 16),
              Icon(Icons.close, color: Colors.grey[600]),
              const SizedBox(width: 16),
              _buildFormulaStep('🟢', 'Kar Marjı', 'ÇARPILIR', Colors.green[100]!),
              const SizedBox(width: 16),
              Icon(Icons.arrow_forward, color: Colors.grey[600]),
              const SizedBox(width: 16),
              _buildFormulaStep('💰', 'Final Fiyat', 'SONUÇ', Colors.blue[100]!),
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
    return Expanded(
      child: Container(
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
      ),
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color[900],
            ),
          ),
        ],
      ),
    );
  }
}
