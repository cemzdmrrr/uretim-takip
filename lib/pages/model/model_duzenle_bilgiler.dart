// ignore_for_file: invalid_use_of_protected_member
part of 'model_duzenle.dart';

/// Model düzenleme - model bilgileri formu
extension _BilgilerDuzenleExt on _ModelDuzenlePageState {
  Widget _buildModelBilgileriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Temel Model Bilgileri
          _buildSectionTitle('1. Temel Model Bilgileri'),
          _buildTextFormField(
            controller: _markaController,
            label: 'Marka *',
            validator: (value) => value?.isEmpty ?? true ? 'Marka gerekli' : null,
          ),
          _buildTextFormField(
            controller: _itemNoController,
            label: 'Model Kodu *',
            hint: 'örn: TRK001-2025',
            validator: (value) => value?.isEmpty ?? true ? 'Model kodu gerekli' : null,
          ),
          _buildTextFormField(
            controller: _modelAdiController,
            label: 'Model Adı',
            hint: 'örn: Basic Crew Neck Sweater',
          ),
          _buildTextFormField(
            controller: _sezonController,
            label: 'Sezon',
            hint: 'örn: İlkbahar/Yaz, Sonbahar/Kış, Tüm Sezon',
          ),

          const SizedBox(height: 20),

          // 2. Ürün Detayları
          _buildSectionTitle('2. Ürün Detayları'),
          _buildTextFormField(
            controller: _urunKategorisiController,
            label: 'Ürün Kategorisi',
            hint: 'örn: Kazak, Hırka, Yelek, Elbise, Pantolon',
          ),
          _buildTextFormField(
            controller: _trikoTipiController,
            label: DalFormConfig.urunTipiEtiketi(_aktifDal),
            hint: DalFormConfig.urunTipiHint(_aktifDal),
          ),
          _buildTextFormField(
            controller: _cinsiyetController,
            label: 'Cinsiyet',
            hint: 'örn: Erkek, Kadın, Çocuk, Unisex',
          ),
          _buildTextFormField(
            controller: _yakaTipiController,
            label: 'Yaka Tipi',
            hint: 'örn: Bisiklet yaka, V yaka, Polo yaka, Balıkçı yaka',
          ),

          const SizedBox(height: 20),

          // 3. İplik ve Materyal (sadece ilgili dallar)
          if (DalFormConfig.iplikBolumuGoster(_aktifDal)) ...[
            _buildSectionTitle('3. İplik ve Materyal Bilgileri'),
            _buildTextFormField(
              controller: _anaIplikTuruController,
              label: 'Ana İplik Türü',
              hint: 'örn: Pamuk, Yün, Akrilik, Kaşmir, Alpaka',
            ),
            _buildTextFormField(
              controller: _iplikKarisimiController,
              label: 'İplik Karışımı',
              hint: 'örn: %50 Pamuk %50 Akrilik',
            ),
            _buildTextFormField(
              controller: _iplikMarkasiController,
              label: 'İplik Markası',
              hint: 'örn: Pamukkale, Kartopu, Nako',
            ),
            _buildTextFormField(
              controller: _iplikRenkKoduController,
              label: 'İplik Renk Kodu',
              hint: 'Pantone/RAL renk kodları',
            ),
            _buildTextFormField(
              controller: _iplikNumarasiController,
              label: 'İplik Numarası',
              hint: 'örn: Ne 20/1, Ne 30/1',
            ),
          ],

          const SizedBox(height: 20),

          // 4. Renk ve Desen
          _buildSectionTitle('4. Renk ve Desen'),
          _buildTextFormField(
            controller: _desenTipiController,
            label: 'Desen Tipi',
            hint: 'örn: Düz, Çizgili, Noktalı, Jakarlı desen, Argyle',
          ),
          _buildTextFormField(
            controller: _desenDetayiController,
            label: 'Desen Detayı',
            hint: 'Desen açıklaması veya kodu',
          ),
          _buildTextFormField(
            controller: _renkKombinasyonuController,
            label: 'Ana Renk',
            hint: 'Model ana rengi (örn: Siyah, Beyaz, Mavi)',
          ),

          const SizedBox(height: 20),

          // 5. Beden Dağılımı
          _buildSectionTitle('5. Beden Dağılımı'),
          _buildBedenDagilimi(),

          const SizedBox(height: 20),

          // 6. Ölçü Bilgileri
          if (DalFormConfig.gramajGoster(_aktifDal)) ...[
            _buildSectionTitle('6. Ölçü Bilgileri'),
            _buildTextFormField(
              controller: _gramajController,
              label: 'Gramaj',
              hint: 'örn: 200g/m², 350g/m²',
            ),
          ],

          const SizedBox(height: 20),

          // 7. Teknik Örgü Bilgileri (sadece triko/örme dalları)
          if (DalFormConfig.teknikOrguGoster(_aktifDal)) ...[
            _buildSectionTitle('7. Teknik Örgü Bilgileri'),
            _buildTextFormField(
              controller: _makineTipiController,
              label: 'Makine Tipi',
              hint: 'örn: Yuvarlak örgü, Düz örgü, Raschel',
            ),
            _buildTextFormField(
              controller: _igneNoController,
              label: 'İğne No',
              hint: 'örn: E7, E10, E12, E14',
            ),
            _buildTextFormField(
              controller: _gaugeController,
              label: 'Gauge',
              hint: 'örn: 5gg, 7gg, 12gg, 14gg',
            ),
            _buildTextFormField(
              controller: _orguSikligiController,
              label: 'Örgü Sıklığı',
              hint: 'örn: Gevşek, Normal, Sıkı',
            ),
            _buildTextFormField(
              controller: _teknikGramajController,
              label: 'Teknik Gramaj',
              hint: 'örn: 200g/m², 350g/m²',
            ),
          ],

          const SizedBox(height: 20),

          // 8. Tarihler ve Durum
          _buildSectionTitle('8. Tarihler ve Durum'),
          _buildDatePicker(
            label: 'Sipariş Tarihi',
            selectedDate: _siparisTarihi,
            onDateSelected: (date) => setState(() => _siparisTarihi = date),
          ),
          _buildDatePicker(
            label: 'Termin Tarihi',
            selectedDate: _terminTarihi,
            onDateSelected: (date) => setState(() => _terminTarihi = date),
          ),
          _buildTextFormField(
            controller: _durumController,
            label: 'Durum',
            hint: 'örn: Beklemede, Planlama, Üretim, Tamamlandı, İptal',
          ),

          const SizedBox(height: 20),

          // 9. Notlar
          _buildSectionTitle('9. Notlar ve Talimatlar'),
          _buildTextFormField(
            controller: _ozelTalimatlarController,
            label: 'Özel Talimatlar',
            hint: 'Model için özel notlar',
            maxLines: 3,
          ),
          _buildTextFormField(
            controller: _genelNotlarController,
            label: 'Genel Notlar',
            hint: 'Genel açıklamalar',
            maxLines: 3,
          ),

          const SizedBox(height: 30),

          // Güncelle butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _guncelleModel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Modeli Güncelle', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal),
          ),
        ),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            locale: const Locale('tr'),
          );
          if (date != null) {
            onDateSelected(date);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDate != null
                    ? '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}'
                    : label,
                style: TextStyle(
                  color: selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
              const Icon(Icons.calendar_today),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBedenDagilimi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Toplam Adet: ${_calculateTotalQuantity()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addBeden,
              icon: const Icon(Icons.add),
              label: const Text('Beden Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bedenler.length,
          itemBuilder: (context, index) {
            final beden = _bedenler[index];
            final bedenController = beden['bedenController'] as TextEditingController;
            final adetController = beden['adetController'] as TextEditingController;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: bedenController,
                      decoration: InputDecoration(
                        labelText: 'Beden',
                        hintText: 'örn: S, M, L, 38, 40',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: adetController,
                      decoration: InputDecoration(
                        labelText: 'Adet',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _bedenler.length > 1 ? () => _removeBeden(index) : null,
                    icon: const Icon(Icons.delete),
                    color: AppTheme.errorColor,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _addBeden() {
    setState(() {
      _bedenler.add({
        'beden': '',
        'adet': 0,
        'bedenController': TextEditingController(),
        'adetController': TextEditingController(),
      });
    });
  }

  void _removeBeden(int index) {
    if (_bedenler.length > 1) {
      setState(() {
        _bedenler[index]['bedenController']?.dispose();
        _bedenler[index]['adetController']?.dispose();
        _bedenler.removeAt(index);
      });
    }
  }
}
