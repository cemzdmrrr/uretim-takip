part of 'model_detay.dart';

extension _MaliyetKarlilikTabExt on _ModelDetayState {
  Widget _buildMaliyetKarlilikTab() {
    final hesaplananOzet = const ModelKarlilikServisi().hesapla(
      model: currentModelData ?? const {},
      uretimKayitlari: _tumUretimKayitlari(),
      modelAksesuarlari: modelAksesuarlari,
    );
    final ozet = _dbOzettenKarlilikOzeti(hesaplananOzet) ?? hesaplananOzet;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKarlilikBaslik(ozet),
            const SizedBox(height: 16),
            _buildVeriKaynagiOzeti(),
            const SizedBox(height: 16),
            _buildKarlilikKpiGrid(ozet),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final children = [
                  Expanded(child: _buildHedefPlanGerceklesen(ozet)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKararPaneli(
                      ozet,
                      guncelFiyatlandirmaOzeti: hesaplananOzet,
                    ),
                  ),
                ];
                if (wide) {
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children);
                }
                return Column(
                  children: [
                    _buildHedefPlanGerceklesen(ozet),
                    const SizedBox(height: 16),
                    _buildKararPaneli(
                      ozet,
                      guncelFiyatlandirmaOzeti: hesaplananOzet,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMaliyetKalemleriTablosu(ozet),
            const SizedBox(height: 16),
            _buildHesapDenetimiPanel(ozet),
            const SizedBox(height: 16),
            _buildGerceklesenMaliyetPanel(ozet),
          ],
        ),
      ),
    );
  }

  List<dynamic> _tumUretimKayitlari() => [
        ...orguUretimKayitlari,
        ...konfeksiyonUretimKayitlari,
        ...nakisUretimKayitlari,
        ...yikamaUretimKayitlari,
        ...ilikDugmeUretimKayitlari,
        ...utuUretimKayitlari,
      ];

  Future<void> _maliyetVerileriniGetir() async {
    try {
      final ozet = await supabase
          .from(DbTables.modelKarlilikOzetleri)
          .select('*')
          .eq('model_id', widget.modelId)
          .maybeSingle();

      final planlar = await supabase
          .from(DbTables.modelMaliyetPlanlari)
          .select('*')
          .eq('model_id', widget.modelId)
          .order('versiyon_no', ascending: false);

      final aktifPlan = planlar.cast<Map<String, dynamic>?>().firstWhere(
            (plan) => plan?['durum'] == 'aktif',
            orElse: () => planlar.isNotEmpty
                ? Map<String, dynamic>.from(planlar.first)
                : null,
          );

      final kalemler = aktifPlan == null
          ? <dynamic>[]
          : await supabase
              .from(DbTables.modelMaliyetKalemleri)
              .select('*')
              .eq('plan_id', aktifPlan['id'])
              .order('sira_no', ascending: true)
              .order('created_at', ascending: true);

      final gerceklesen = await supabase
          .from(DbTables.modelMaliyetGerceklesen)
          .select('*')
          .eq('model_id', widget.modelId)
          .order('tarih', ascending: false)
          .order('created_at', ascending: false);

      if (!mounted) return;
      _updateState(() {
        karlilikDbOzet = ozet == null ? null : Map<String, dynamic>.from(ozet);
        maliyetPlanlari = List<dynamic>.from(planlar);
        maliyetKalemleri = List<dynamic>.from(kalemler);
        maliyetGerceklesen = List<dynamic>.from(gerceklesen);
      });
    } catch (e) {
      debugPrint('Maliyet verileri alınamadı: $e');
    }
  }

  ModelKarlilikOzeti? _dbOzettenKarlilikOzeti(ModelKarlilikOzeti fallback) {
    final db = karlilikDbOzet;
    if (db == null) return null;

    final siparisAdedi = _intDeger(db['siparis_adedi']);
    final tamamlananAdet = _intDeger(db['tamamlanan_adet']);
    final fireAdedi = _intDeger(db['fire_adedi']);
    final hedefKarMarji = _aktifPlanDegeri('hedef_kar_marji') ??
        (fallback.hedefKarMarji > 0 ? fallback.hedefKarMarji : 0);
    final satisAdedi = tamamlananAdet > 0 ? tamamlananAdet : siparisAdedi;
    final maliyetAdedi = tamamlananAdet > 0
        ? tamamlananAdet + fireAdedi
        : siparisAdedi + fireAdedi;
    final kalemler = _dbMaliyetKalemleri(
      satisAdedi,
      maliyetAdedi,
      fallback.kalemler,
    );
    final planBirim =
        kalemler.fold<double>(0, (sum, kalem) => sum + kalem.planBirim);
    final gercekBirim =
        kalemler.fold<double>(0, (sum, kalem) => sum + kalem.gercekBirim);
    final planToplam = planBirim * siparisAdedi;
    final gercekToplam = gercekBirim * satisAdedi;
    final satisBirim = _hesaplananSatisFiyati(planBirim, hedefKarMarji);
    final satisGeliri = satisBirim * satisAdedi;
    final brutKar = satisGeliri - gercekToplam;
    final brutKarMarji = satisGeliri > 0 ? (brutKar / satisGeliri) * 100 : 0.0;
    final maliyetSapmasi = gercekBirim - planBirim;
    final maliyetSapmaOrani =
        planBirim > 0 ? (maliyetSapmasi / planBirim) * 100 : 0.0;

    return ModelKarlilikOzeti(
      siparisAdedi: siparisAdedi,
      tamamlananAdet: tamamlananAdet,
      fireAdedi: fireAdedi,
      planBirimMaliyet: planBirim,
      gercekBirimMaliyet: gercekBirim,
      planToplamMaliyet: planToplam,
      gercekToplamMaliyet: gercekToplam,
      satisBirimFiyati: satisBirim,
      satisGeliri: satisGeliri,
      brutKar: brutKar,
      brutKarMarji: brutKarMarji,
      maliyetSapmasi: maliyetSapmasi,
      maliyetSapmaOrani: maliyetSapmaOrani,
      fireOrani: siparisAdedi > 0 ? (fireAdedi / siparisAdedi) * 100 : 0,
      tamamlanmaOrani:
          siparisAdedi > 0 ? (tamamlananAdet / siparisAdedi) * 100 : 0,
      hedefKarMarji: hedefKarMarji,
      minimumFiyat: gercekBirim,
      onerilenFiyat: gercekBirim * (1 + hedefKarMarji / 100),
      tamamlananAdetKaynak: _tamamlananAdetKaynak(),
      tamamlananAsama: _tamamlananAsama(),
      kalemler: kalemler,
    );
  }

  double _hesaplananSatisFiyati(double planBirim, double karMarji) {
    var satisFiyati = planBirim * (1 + karMarji / 100);
    final vadeAy = _intDeger(currentModelData?['vade_ay']);
    final vadeOrani = _doubleDeger(currentModelData?['vade_orani']);
    if (vadeAy > 0 && vadeOrani > 0) {
      satisFiyati *= 1 + vadeOrani / 100;
    }
    return satisFiyati;
  }

  List<MaliyetKalemi> _dbMaliyetKalemleri(
    int satisAdedi,
    int maliyetAdedi,
    List<MaliyetKalemi> fallback,
  ) {
    if (maliyetKalemleri.isEmpty) return fallback;

    final gerceklesenToplamlari = <String, double>{};
    final gerceklesenMiktarlari = <String, double>{};
    for (final kayit in maliyetGerceklesen) {
      if (kayit is! Map) continue;
      final tip = kayit['kalem_tipi']?.toString() ?? 'diger';
      gerceklesenToplamlari[tip] = (gerceklesenToplamlari[tip] ?? 0) +
          _doubleDeger(kayit['toplam_tutar']);
      gerceklesenMiktarlari[tip] =
          (gerceklesenMiktarlari[tip] ?? 0) + _doubleDeger(kayit['miktar']);
    }

    final dbKalemler = maliyetKalemleri.whereType<Map>().where((kalem) {
      return kalem['kalem_tipi']?.toString() != 'aksesuar';
    }).map((kalem) {
      final kod = kalem['kalem_tipi']?.toString() ?? 'diger';
      final plan = _doubleDeger(kalem['plan_birim_maliyet']);
      final gercekToplam = gerceklesenToplamlari[kod] ?? 0;
      final gercekMiktar = gerceklesenMiktarlari[kod] ?? 0;
      final gercek = gercekToplam > 0
          ? (gercekMiktar > 0
              ? gercekToplam / gercekMiktar
              : (satisAdedi > 0 ? gercekToplam / satisAdedi : gercekToplam))
          : (satisAdedi > 0 && maliyetAdedi > 0
              ? plan * (maliyetAdedi / satisAdedi)
              : plan);
      return MaliyetKalemi(
        kod: kod,
        ad: kalem['aciklama']?.toString() ?? kod,
        planBirim: plan,
        gercekBirim: gercek,
      );
    }).toList();

    return _aksesuarKalemleriniNormalizeEt(dbKalemler);
  }

  List<MaliyetKalemi> _aksesuarKalemleriniNormalizeEt(
    List<MaliyetKalemi> kalemler,
  ) {
    final manuelGenelAksesuar =
        _doubleDeger(currentModelData?['genel_aksesuar_fiyat']);

    final normalized = kalemler.map((kalem) {
      if (kalem.kod != 'genel_aksesuar') return kalem;
      if (manuelGenelAksesuar <= 0) return kalem;

      final gercek = kalem.planBirim > 0
          ? kalem.gercekBirim * (manuelGenelAksesuar / kalem.planBirim)
          : manuelGenelAksesuar;
      return MaliyetKalemi(
        kod: kalem.kod,
        ad: 'Genel Aksesuar',
        planBirim: manuelGenelAksesuar,
        gercekBirim: gercek,
      );
    }).toList();

    return normalized.where((kalem) => kalem.planBirim > 0).toList();
  }

  Widget _buildKarlilikBaslik(ModelKarlilikOzeti ozet) {
    final durum = _karlilikDurumu(ozet);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: durum.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(durum.icon, color: durum.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maliyet & Karlılık Kokpiti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentModelData?['item_no'] ?? '-'} · ${currentModelData?['marka'] ?? '-'}',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: durum.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: durum.color.withValues(alpha: 0.35)),
            ),
            child: Text(
              durum.label,
              style: TextStyle(
                color: durum.color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKarlilikKpiGrid(ModelKarlilikOzeti ozet) {
    final karOraniLabel =
        ozet.uretimGerceklesmedi ? 'Plan Kar Oranı' : 'Gerçek Kar Oranı';
    final karOraniAciklama = ozet.uretimGerceklesmedi
        ? 'Üretim yokken satış fiyatı ve plan maliyet üzerinden proforma kar oranı.'
        : 'Brüt karın gerçekleşen maliyete oranı. Hedef kar oranıyla aynı bazdadır.';
    final items = [
      _KpiData(
        'Plan Birim Maliyet',
        _para(ozet.planBirimMaliyet),
        'Aktif plandaki maliyet kalemlerinin adet başı toplamı.',
        Icons.calculate,
        const Color(0xFF1565C0),
      ),
      _KpiData(
        'Gerçek Birim Maliyet',
        _para(ozet.gercekBirimMaliyet),
        'Girilen gerçekleşen tutarlar ve fire etkisiyle oluşan adet başı maliyet.',
        Icons.receipt,
        _sapmaRengi(ozet.maliyetSapmasi),
      ),
      _KpiData(
        'Satış Fiyatı',
        _para(ozet.satisBirimFiyati),
        'Fiyatlandırma sekmesindeki kayıtlı satış fiyatı.',
        Icons.local_offer,
        const Color(0xFF2E7D32),
      ),
      _KpiData(
          'Brüt Kar',
          _para(ozet.brutKar),
          'Satış geliri ile gerçekleşen toplam maliyet arasındaki fark.',
          Icons.trending_up,
          ozet.brutKar >= 0
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828)),
      _KpiData(
          karOraniLabel,
          _yuzde(ozet.gercekKarOrani),
          karOraniAciklama,
          Icons.percent,
          ozet.hedefAltinda
              ? const Color(0xFFC62828)
              : const Color(0xFF2E7D32)),
      _KpiData(
          'Fire Oranı',
          _yuzde(ozet.fireOrani),
          'Fire adedinin sipariş adedine oranı.',
          Icons.warning_amber,
          ozet.fireOrani > 3
              ? const Color(0xFFC62828)
              : const Color(0xFFEF6C00)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map(_buildKpiCard).toList(),
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return Container(
      width: 292,
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 20, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF607D8B)),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeriKaynagiOzeti() {
    final aktifPlan = _aktifPlan();
    final planAdi = aktifPlan == null
        ? 'Anlık hesap'
        : 'Aktif plan v${_intDeger(aktifPlan['versiyon_no'])}';
    final planDurumu =
        aktifPlan == null ? 'Henüz kayıtlı plan yok' : 'SQL planından okunuyor';
    final gerceklesenAdet = maliyetGerceklesen.length;
    final sonKayit = _sonGerceklesenTarihi();
    final ozetKaynak =
        karlilikDbOzet == null ? 'Ekran içi hesap' : 'SQL özeti güncel';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _bilgiRozeti(Icons.assignment, 'Plan Kaynağı', planAdi, planDurumu),
          _bilgiRozeti(Icons.receipt, 'Gerçekleşen', '$gerceklesenAdet kayıt',
              sonKayit ?? 'Kayıt girilmedi'),
          _bilgiRozeti(Icons.sync, 'Özet Kaynağı', ozetKaynak,
              'Plan veya gerçekleşen değişince yenilenir'),
        ],
      ),
    );
  }

  Widget _buildHedefPlanGerceklesen(ModelKarlilikOzeti ozet) {
    final karOraniLabel =
        ozet.uretimGerceklesmedi ? 'Plan Kar Oranı' : 'Gerçek Kar Oranı';
    return _panel(
      title: 'Hedef / Plan / Gerçekleşen',
      icon: Icons.stacked_line_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _karsilastirmaSatiri('Hedef Kar Oranı', _yuzde(ozet.hedefKarMarji),
              karOraniLabel, _yuzde(ozet.gercekKarOrani),
              negative: ozet.hedefAltinda),
          _karsilastirmaSatiri(
              'Hedef Brüt Eşdeğer',
              _yuzde(ozet.hedefBrutKarMarji),
              'Satış Üstü Brüt Marj',
              _yuzde(ozet.brutKarMarji),
              negative: false),
          _karsilastirmaSatiri('Plan Maliyet', _para(ozet.planBirimMaliyet),
              'Gerçek Maliyet', _para(ozet.gercekBirimMaliyet),
              negative: ozet.maliyetSapmasi > 0),
          _karsilastirmaSatiri('Sipariş Adedi', _adet(ozet.siparisAdedi),
              'Tamamlanan', _adet(ozet.tamamlananAdet),
              negative: ozet.tamamlanmaOrani < 100 && ozet.tamamlananAdet > 0),
          _karsilastirmaSatiri('Fire Adedi', _adet(ozet.fireAdedi),
              'Fire Etkisi', _para(ozet.fireAdedi * ozet.planBirimMaliyet),
              negative: ozet.fireAdedi > 0),
          const Divider(height: 18, color: Color(0xFFE7ECF2)),
          _hesaplamaSatiri('Plan maliyet',
              'Aktif plan kalemleri toplanarak adet başı maliyet bulunur.'),
          _hesaplamaSatiri('Gerçek maliyet',
              'Gerçekleşen maliyet kayıtları varsa bunlar, yoksa plan/proforma tahmin kullanılır.'),
          _hesaplamaSatiri('Kar oranı',
              'Brüt karın maliyete oranıdır; hedef kar oranı ile aynı bazda karşılaştırılır.'),
          _hesaplamaSatiri('Brüt marj',
              'Satış üstü marjdır; bilgi amaçlı ayrıca gösterilir.'),
          _hesaplamaSatiri('Hedef fiyat',
              'Gerçek birim maliyet üzerine hedef kar marjı eklenir.'),
        ],
      ),
    );
  }

  Widget _buildKararPaneli(
    ModelKarlilikOzeti ozet, {
    required ModelKarlilikOzeti guncelFiyatlandirmaOzeti,
  }) {
    final oneriler = <String>[
      if (ozet.satisFiyatiEksik)
        'Satış fiyatı eksik. Karlılık takibi için fiyatlandırma sekmesinde peşin fiyatı kaydedin.',
      if (ozet.uretimGerceklesmedi && !ozet.satisFiyatiEksik)
        'Üretim tamamlanmadığı için marj plan/proforma seviyedir; gerçek marj üretim ve fire kayıtlarıyla kesinleşir.',
      if (ozet.zararRiski)
        'Model zarar bölgesinde. Satış fiyatı gerçek birim maliyetin altında kalıyor.',
      if (ozet.hedefAltinda && !ozet.zararRiski)
        '${ozet.uretimGerceklesmedi ? 'Plan kar oranı' : 'Gerçek kar oranı'} hedefin altında. Fiyat, fire veya fason kalemlerini yeniden kontrol edin.',
      if (ozet.fireOrani > 3)
        'Fire oranı yüksek. Fire maliyeti birim maliyeti yukarı taşıyor.',
      if (!ozet.satisFiyatiEksik && !ozet.hedefAltinda && ozet.fireOrani <= 3)
        'Model hedef karlılık bandında görünüyor.',
    ];

    return _panel(
      title: 'Karar Destek',
      icon: Icons.checklist,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kararMetrigi(
              'Minimum Fiyat', _para(ozet.minimumFiyat), Icons.attach_money),
          _kararMetrigi('Hedef Fiyat', _para(ozet.onerilenFiyat), Icons.flag),
          _kararMetrigi('Maliyet Sapması', _para(ozet.maliyetSapmasi),
              Icons.compare_arrows),
          _kararMetrigi(
              'Sapma Oranı', _yuzde(ozet.maliyetSapmaOrani), Icons.percent),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _aktifMaliyetPlaniKaydet(guncelFiyatlandirmaOzeti),
              icon: const Icon(Icons.save),
              label: const Text('Mevcut fiyatlandırmayı aktif plan yap'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _gerceklesenMaliyetEkleDialog(ozet),
              icon: const Icon(Icons.add_box),
              label: const Text('Gerçekleşen maliyet ekle'),
            ),
          ),
          const SizedBox(height: 10),
          ...oneriler.map(
            (onerme) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFF607D8B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      onerme,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaliyetKalemleriTablosu(ModelKarlilikOzeti ozet) {
    return _panel(
      title: 'Maliyet Kalemleri',
      icon: Icons.table_rows,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan sütunu hedeflenen adet başı maliyeti, gerçek sütunu ise kayıtlı gerçekleşen tutarların adet başı etkisini gösterir.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF607D8B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFFEEF3F8),
            child: const Row(
              children: [
                Expanded(flex: 22, child: _TableHeader('Kalem')),
                Expanded(flex: 12, child: _TableHeader('Plan')),
                Expanded(flex: 12, child: _TableHeader('Gerçek')),
                Expanded(flex: 12, child: _TableHeader('Sapma')),
              ],
            ),
          ),
          if (ozet.kalemler.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Maliyet kalemi bulunmuyor.'),
            )
          else
            ...ozet.kalemler.map((kalem) => _maliyetKalemiSatiri(kalem)),
        ],
      ),
    );
  }

  Widget _buildGerceklesenMaliyetPanel(ModelKarlilikOzeti ozet) {
    return _panel(
      title: 'Gerçekleşen Maliyet Kayıtları',
      icon: Icons.receipt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (maliyetGerceklesen.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Henüz gerçekleşen maliyet kaydı yok. Kayıt yokken gerçek maliyet, plan maliyet ve fire üzerinden tahmin edilir.',
                style: TextStyle(color: Color(0xFF607D8B)),
              ),
            )
          else ...[
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFFEEF3F8),
              child: const Row(
                children: [
                  Expanded(flex: 12, child: _TableHeader('Tarih')),
                  Expanded(flex: 14, child: _TableHeader('Kaynak')),
                  Expanded(flex: 18, child: _TableHeader('Kalem')),
                  Expanded(flex: 14, child: _TableHeader('Tutar')),
                  Expanded(flex: 22, child: _TableHeader('Açıklama')),
                ],
              ),
            ),
            ...maliyetGerceklesen
                .whereType<Map>()
                .take(12)
                .map(_gerceklesenMaliyetSatiri),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _gerceklesenMaliyetEkleDialog(ozet),
              icon: const Icon(Icons.add),
              label: const Text('Kayıt ekle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHesapDenetimiPanel(ModelKarlilikOzeti ozet) {
    final satirlar = _denetimSatirlari(ozet);
    return _panel(
      title: 'Hesap Denetimi',
      icon: Icons.assignment_turned_in,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bu tablo ana göstergelerin hangi kaynak, formül ve varsayımla hesaplandığını gösterir. Uyarı varsa rakam karar desteği için kullanılmalı, kesin muhasebe sonucu gibi okunmamalıdır.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF607D8B),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1160,
              child: Column(
                children: [
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: const Color(0xFFEEF3F8),
                    child: const Row(
                      children: [
                        Expanded(flex: 13, child: _TableHeader('Gösterge')),
                        Expanded(flex: 16, child: _TableHeader('Kaynak')),
                        Expanded(flex: 25, child: _TableHeader('Formül')),
                        Expanded(
                            flex: 24, child: _TableHeader('Kullanılan Değer')),
                        Expanded(flex: 22, child: _TableHeader('Denetim Notu')),
                      ],
                    ),
                  ),
                  ...satirlar.map(_denetimSatiri),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DenetimSatiri> _denetimSatirlari(ModelKarlilikOzeti ozet) {
    final aktifPlan = _aktifPlan();
    final planKaynak = aktifPlan == null
        ? 'Model alanlarından anlık hesap'
        : 'Aktif maliyet planı v${_intDeger(aktifPlan['versiyon_no'])}';
    final gercekKaynak = maliyetGerceklesen.isEmpty
        ? 'Plan/proforma tahmin'
        : '${maliyetGerceklesen.length} gerçekleşen kayıt';
    final satisAdedi =
        ozet.tamamlananAdet > 0 ? ozet.tamamlananAdet : ozet.siparisAdedi;
    final maliyetBazAdet =
        ozet.tamamlananAdet > 0 ? ozet.tamamlananAdet : ozet.siparisAdedi;
    final gercekToplamKaynak = maliyetGerceklesen.isEmpty
        ? 'Kayıt yok; gerçek maliyet yerine plan/proforma maliyet kullanılıyor'
        : 'Gerçekleşen kayıt toplamı ve RPC özeti kullanılıyor';

    return [
      _DenetimSatiri(
        gosterge: 'Sipariş Adedi',
        kaynak: aktifPlan == null ? 'Model kartı' : 'Aktif plan',
        formul: 'Plan adedi veya model toplam_adet',
        kullanilanDeger: _adet(ozet.siparisAdedi),
        not: ozet.siparisAdedi > 0
            ? 'Sipariş baz adedi mevcut'
            : 'Sipariş adedi boş; toplam hesaplar eksik kalabilir',
        uyari: ozet.siparisAdedi <= 0,
      ),
      _DenetimSatiri(
        gosterge: 'Tamamlanan',
        kaynak: ozet.tamamlananAdetKaynak,
        formul: 'En ileri üretim aşamasındaki kabul/tamamlanan/üretilen adet',
        kullanilanDeger: _adet(ozet.tamamlananAdet),
        not: ozet.tamamlananAdet > 0
            ? '${_asamaEtiketi(ozet.tamamlananAsama)} aşaması baz alınıyor'
            : 'Üretim tamamı yok; gerçek satış ve marj kesinleşmedi',
        uyari: ozet.tamamlananAdet <= 0,
      ),
      _DenetimSatiri(
        gosterge: 'Plan Maliyet',
        kaynak: planKaynak,
        formul: 'Maliyet kalemleri toplamı',
        kullanilanDeger:
            '${_para(ozet.planBirimMaliyet)} x ${_adet(ozet.siparisAdedi)} = ${_para(ozet.planToplamMaliyet)}',
        not: aktifPlan == null
            ? 'Henüz kilitli plan yok; rakam model alanlarından gelir'
            : 'Aktif plan kayıtlı',
        uyari: aktifPlan == null || ozet.planBirimMaliyet <= 0,
      ),
      _DenetimSatiri(
        gosterge: 'Gerçek Maliyet',
        kaynak: gercekKaynak,
        formul: 'Gerçek toplam maliyet / maliyet baz adedi',
        kullanilanDeger:
            '${_para(ozet.gercekToplamMaliyet)} / ${_adet(maliyetBazAdet)} = ${_para(ozet.gercekBirimMaliyet)}',
        not: gercekToplamKaynak,
        uyari: maliyetGerceklesen.isEmpty || maliyetBazAdet <= 0,
      ),
      _DenetimSatiri(
        gosterge: 'Satış Geliri',
        kaynak: 'Fiyatlandırma sekmesi',
        formul: 'Satış fiyatı x satış adedi',
        kullanilanDeger:
            '${_para(ozet.satisBirimFiyati)} x ${_adet(satisAdedi)} = ${_para(ozet.satisGeliri)}',
        not: ozet.satisFiyatiEksik
            ? 'Satış fiyatı yok; marj güvenilir değil'
            : 'Satış fiyatı mevcut',
        uyari: ozet.satisFiyatiEksik,
      ),
      _DenetimSatiri(
        gosterge: 'Brüt Kar',
        kaynak: 'Özet hesap',
        formul: 'Satış geliri - gerçek toplam maliyet',
        kullanilanDeger:
            '${_para(ozet.satisGeliri)} - ${_para(ozet.gercekToplamMaliyet)} = ${_para(ozet.brutKar)}',
        not: ozet.brutKar >= 0
            ? 'Model brüt karda görünüyor'
            : 'Model brüt zararda görünüyor',
        uyari: ozet.brutKar < 0,
      ),
      _DenetimSatiri(
        gosterge: 'Kar Marjı',
        kaynak: ozet.uretimGerceklesmedi ? 'Plan/proforma hesap' : 'Özet hesap',
        formul: 'Brüt kar / maliyet',
        kullanilanDeger:
            '${_yuzde(ozet.gercekKarOrani)} hedef: ${_yuzde(ozet.hedefKarMarji)}',
        not: ozet.hedefAltinda
            ? '${ozet.uretimGerceklesmedi ? 'Plan kar oranı' : 'Gerçek kar oranı'} hedefin altında'
            : '${ozet.uretimGerceklesmedi ? 'Plan kar oranı' : 'Gerçek kar oranı'} hedefi karşılıyor',
        uyari: ozet.hedefAltinda,
      ),
      _DenetimSatiri(
        gosterge: 'Fire',
        kaynak: 'Üretim kayıtları',
        formul: 'Fire adedi / sipariş adedi',
        kullanilanDeger:
            '${_adet(ozet.fireAdedi)} / ${_adet(ozet.siparisAdedi)} = ${_yuzde(ozet.fireOrani)}',
        not: ozet.fireOrani > 3
            ? 'Fire oranı maliyeti anlamlı artırabilir'
            : 'Fire oranı kontrol bandında',
        uyari: ozet.fireOrani > 3,
      ),
      _DenetimSatiri(
        gosterge: 'Hedef Fiyat',
        kaynak: 'Karar destek',
        formul: 'Gerçek birim maliyet x (1 + hedef marj)',
        kullanilanDeger:
            '${_para(ozet.gercekBirimMaliyet)} x ${_yuzde(100 + ozet.hedefKarMarji)} = ${_para(ozet.onerilenFiyat)}',
        not: ozet.satisBirimFiyati >= ozet.onerilenFiyat
            ? 'Mevcut fiyat hedef fiyatın üstünde'
            : 'Mevcut fiyat hedef fiyatın altında',
        uyari: !ozet.satisFiyatiEksik &&
            ozet.satisBirimFiyati < ozet.onerilenFiyat,
      ),
    ];
  }

  Widget _denetimSatiri(_DenetimSatiri satir) {
    final color =
        satir.uyari ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECF2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 13,
            child: Text(
              satir.gosterge,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(flex: 16, child: Text(satir.kaynak)),
          Expanded(flex: 25, child: Text(satir.formul)),
          Expanded(
            flex: 24,
            child: Text(
              satir.kullanilanDeger,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  satir.uyari ? Icons.warning_amber : Icons.check_circle,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    satir.not,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gerceklesenMaliyetSatiri(Map kayit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECF2))),
      ),
      child: Row(
        children: [
          Expanded(flex: 12, child: Text(_tarihMetni(kayit['tarih']))),
          Expanded(flex: 14, child: Text(kayit['kaynak']?.toString() ?? '-')),
          Expanded(
              flex: 18, child: Text(_kalemTipiEtiketi(kayit['kalem_tipi']))),
          Expanded(
            flex: 14,
            child: Text(
              _para(_doubleDeger(kayit['toplam_tutar'])),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              kayit['aciklama']?.toString() ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _maliyetKalemiSatiri(MaliyetKalemi kalem) {
    final sapmaRengi = _sapmaRengi(kalem.sapmaBirim);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECF2))),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 22,
              child: Text(kalem.ad,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 12, child: Text(_para(kalem.planBirim))),
          Expanded(flex: 12, child: Text(_para(kalem.gercekBirim))),
          Expanded(
            flex: 12,
            child: Text(
              '${_para(kalem.sapmaBirim)} (${_yuzde(kalem.sapmaOrani)})',
              style: TextStyle(color: sapmaRengi, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilgiRozeti(
    IconData icon,
    String label,
    String value,
    String description,
  ) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 19, color: const Color(0xFF1565C0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF607D8B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hesaplamaSatiri(String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 17, color: Color(0xFF607D8B)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFF455A64),
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1565C0), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7ECF2)),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _karsilastirmaSatiri(
    String solEtiket,
    String solDeger,
    String sagEtiket,
    String sagDeger, {
    required bool negative,
  }) {
    final color = negative ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: _miniDeger(solEtiket, solDeger)),
          Icon(Icons.arrow_forward, size: 18, color: color),
          Expanded(child: _miniDeger(sagEtiket, sagDeger, valueColor: color)),
        ],
      ),
    );
  }

  Widget _miniDeger(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF607D8B))),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF102A43),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kararMetrigi(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Color(0xFF607D8B)))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  _KarlilikDurumu _karlilikDurumu(ModelKarlilikOzeti ozet) {
    if (ozet.satisFiyatiEksik) {
      return const _KarlilikDurumu(
          'Fiyat Eksik', Icons.info, Color(0xFF607D8B));
    }
    if (ozet.zararRiski) {
      return _KarlilikDurumu(
        ozet.uretimGerceklesmedi ? 'Plan Zarar Riski' : 'Zarar Riski',
        Icons.error_outline,
        const Color(0xFFC62828),
      );
    }
    if (ozet.hedefAltinda) {
      return _KarlilikDurumu(
        ozet.uretimGerceklesmedi ? 'Plan Hedef Altı' : 'Hedef Altı',
        Icons.trending_down,
        const Color(0xFFEF6C00),
      );
    }
    return _KarlilikDurumu(
      ozet.uretimGerceklesmedi ? 'Plan Hedefte' : 'Hedefte',
      Icons.check_circle,
      const Color(0xFF2E7D32),
    );
  }

  Color _sapmaRengi(double value) {
    if (value > 0) return const Color(0xFFC62828);
    if (value < 0) return const Color(0xFF2E7D32);
    return const Color(0xFF607D8B);
  }

  String _para(double value) =>
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
          .format(value);

  String _yuzde(double value) => '%${value.toStringAsFixed(1)}';

  String _adet(int value) => NumberFormat.decimalPattern('tr_TR').format(value);

  Future<void> _aktifMaliyetPlaniKaydet(ModelKarlilikOzeti ozet) async {
    final model = currentModelData;
    if (model == null) return;

    _updateState(() => _isSaving = true);
    try {
      final modelId = model['id'].toString();
      final firmaId = model['firma_id']?.toString() ??
          TenantManager.instance.requireFirmaId;

      final oncekiPlanlar = await supabase
          .from(DbTables.modelMaliyetPlanlari)
          .select('versiyon_no')
          .eq('model_id', modelId)
          .order('versiyon_no', ascending: false)
          .limit(1);
      final oncekiVersiyon = oncekiPlanlar.isNotEmpty
          ? (oncekiPlanlar.first['versiyon_no'] as num?)?.toInt() ?? 0
          : 0;
      final yeniVersiyon = oncekiVersiyon + 1;

      await supabase
          .from(DbTables.modelMaliyetPlanlari)
          .update({
            'durum': 'arsiv',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('model_id', modelId)
          .eq('durum', 'aktif');

      final plan = await supabase
          .from(DbTables.modelMaliyetPlanlari)
          .insert({
            'firma_id': firmaId,
            'model_id': modelId,
            'versiyon_no': yeniVersiyon,
            'durum': 'aktif',
            'plan_tipi': yeniVersiyon == 1 ? 'plan' : 'revize',
            'hedef_kar_marji': ozet.hedefKarMarji,
            'hedef_satis_fiyati': ozet.onerilenFiyat,
            'plan_adet': ozet.siparisAdedi,
            'plan_fire_orani': ozet.fireOrani,
            'plan_birim_maliyet': ozet.planBirimMaliyet,
            'plan_toplam_maliyet': ozet.planToplamMaliyet,
            'plan_satis_fiyati': ozet.satisBirimFiyati,
          })
          .select('id')
          .single();

      final planId = plan['id'].toString();
      if (ozet.kalemler.isNotEmpty) {
        await supabase.from(DbTables.modelMaliyetKalemleri).insert(
              ozet.kalemler
                  .map((kalem) => {
                        'firma_id': firmaId,
                        'model_id': modelId,
                        'plan_id': planId,
                        'kalem_tipi': kalem.kod == 'baski_nakis'
                            ? 'baski_nakis'
                            : kalem.kod,
                        'aciklama': kalem.ad,
                        'miktar': ozet.siparisAdedi,
                        'birim': 'adet',
                        'birim_fiyat': kalem.planBirim,
                        'plan_birim_maliyet': kalem.planBirim,
                        'plan_toplam_tutar':
                            kalem.planBirim * ozet.siparisAdedi,
                        'kaynak': 'model',
                      })
                  .toList(),
            );
      }

      await supabase.rpc('model_karlilik_ozeti_yenile', params: {
        'p_model_id': modelId,
      });
      await _maliyetVerileriniGetir();

      if (!mounted) return;
      context.showSuccessSnackBar('Maliyet planı kaydedildi');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(
          'Maliyet planı kaydedilemedi. SQL migration uygulanmış olmalı: $e');
    } finally {
      _updateState(() => _isSaving = false);
    }
  }

  Future<void> _gerceklesenMaliyetEkleDialog(ModelKarlilikOzeti ozet) async {
    final model = currentModelData;
    if (model == null) return;

    final tutarController = TextEditingController();
    final miktarController = TextEditingController(text: '1');
    final aciklamaController = TextEditingController();
    String kalemTipi =
        ozet.kalemler.isNotEmpty ? ozet.kalemler.first.kod : 'diger';
    String kaynak = 'manuel';

    final kaydedildi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final anlikTutar = _doubleDeger(tutarController.text);
          final anlikMiktar = _doubleDeger(miktarController.text);
          final double anlikBirim = anlikTutar > 0 && anlikMiktar > 0
              ? anlikTutar / anlikMiktar
              : 0.0;

          return AlertDialog(
            title: const Text('Gerçekleşen Maliyet Kaydı'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bu pencere, planlanan maliyetten sonra gerçekten oluşan fatura, stok çıkışı, fason veya manuel gideri modele işler. Kaydettiğiniz tutar modelin gerçek maliyetini ve kar marjını yeniden hesaplatır.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF455A64),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: kalemTipi,
                    decoration: const InputDecoration(
                      labelText: 'Maliyet kalemi',
                      helperText: 'Bu gider hangi maliyet başlığına yazılacak?',
                    ),
                    items: _kalemTipiSecenekleri(ozet)
                        .map((tip) => DropdownMenuItem(
                              value: tip,
                              child: Text(_kalemTipiEtiketi(tip)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => kalemTipi = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: kaynak,
                    decoration: const InputDecoration(
                      labelText: 'Kaynak türü',
                      helperText: 'Tutarın nereden geldiğini belirtir.',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'manuel', child: Text('Manuel')),
                      DropdownMenuItem(value: 'stok', child: Text('Stok')),
                      DropdownMenuItem(value: 'fatura', child: Text('Fatura')),
                      DropdownMenuItem(value: 'uretim', child: Text('Üretim')),
                      DropdownMenuItem(
                          value: 'sevkiyat', child: Text('Sevkiyat')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => kaynak = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: miktarController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Paylaştırılacak miktar',
                            suffixText: 'adet',
                            helperText: 'Tutar kaç adet ürüne dağıtılacak?',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: tutarController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Toplam tutar',
                            prefixText: '₺ ',
                            helperText: 'Fatura veya gider toplamı',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E6EF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate,
                            size: 20, color: Color(0xFF1565C0)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            anlikBirim > 0
                                ? 'Birim maliyet etkisi: ${_para(anlikTutar)} / ${_adet(anlikMiktar.round())} adet = ${_para(anlikBirim)}'
                                : 'Örnek: 10.000 TL gideri 500 adede dağıtırsanız birim etki 20 TL olur.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF455A64),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: aciklamaController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama / belge notu',
                      hintText: 'Örn: Fatura no, tedarikçi, stok fişi, fasoncu',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );

    if (kaydedildi != true) {
      tutarController.dispose();
      miktarController.dispose();
      aciklamaController.dispose();
      return;
    }

    final toplamTutar = _doubleDeger(tutarController.text);
    final miktar = _doubleDeger(miktarController.text);
    final aciklama = aciklamaController.text.trim();
    tutarController.dispose();
    miktarController.dispose();
    aciklamaController.dispose();

    if (toplamTutar <= 0) {
      if (!mounted) return;
      context.showErrorSnackBar('Toplam tutar sıfırdan büyük olmalı');
      return;
    }

    _updateState(() => _isSaving = true);
    try {
      final modelId = model['id'].toString();
      final firmaId = model['firma_id']?.toString() ??
          TenantManager.instance.requireFirmaId;
      final planId = _aktifPlanId();

      await supabase.from(DbTables.modelMaliyetGerceklesen).insert({
        'firma_id': firmaId,
        'model_id': modelId,
        if (planId != null) 'plan_id': planId,
        'kalem_tipi': kalemTipi,
        'kaynak': kaynak,
        'miktar': miktar <= 0 ? 1 : miktar,
        'birim': 'adet',
        'birim_fiyat': miktar > 0 ? toplamTutar / miktar : toplamTutar,
        'toplam_tutar': toplamTutar,
        'tarih': DateTime.now().toIso8601String().split('T').first,
        'aciklama': aciklama.isEmpty ? null : aciklama,
      });

      await supabase.rpc('model_karlilik_ozeti_yenile', params: {
        'p_model_id': modelId,
      });
      await _maliyetVerileriniGetir();

      if (!mounted) return;
      context.showSuccessSnackBar('Gerçekleşen maliyet kaydedildi');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Gerçekleşen maliyet kaydedilemedi: $e');
    } finally {
      _updateState(() => _isSaving = false);
    }
  }

  Map? _aktifPlan() {
    for (final plan in maliyetPlanlari.whereType<Map>()) {
      if (plan['durum'] == 'aktif') return plan;
    }
    if (maliyetPlanlari.isNotEmpty && maliyetPlanlari.first is Map) {
      return maliyetPlanlari.first as Map;
    }
    return null;
  }

  String? _aktifPlanId() {
    return _aktifPlan()?['id']?.toString();
  }

  double? _aktifPlanDegeri(String key) {
    final plan = _aktifPlan();
    return plan == null ? null : _doubleDeger(plan[key]);
  }

  String _tamamlananAdetKaynak() {
    if (_intDeger(currentModelData?['tamamlanan_adet']) > 0) {
      return 'Model kartı';
    }
    return 'SQL karlılık özeti';
  }

  String _tamamlananAsama() {
    final toplamlar = _asamaTamamlananToplamlari();
    if (toplamlar.isEmpty) return '-';
    for (final asama in modelKarlilikAsamaOnceligi) {
      if ((toplamlar[asama] ?? 0) > 0) return asama;
    }
    return toplamlar.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Map<String, int> _asamaTamamlananToplamlari() {
    final totals = <String, int>{};
    for (final kayit in _tumUretimKayitlari()) {
      if (kayit is! Map) continue;
      final asama = kayit['asama']?.toString() ?? 'genel';
      final adet = _intDeger(kayit['kabul_edilen_adet'] ??
          kayit['tamamlanan_adet'] ??
          kayit['uretilen_adet']);
      totals[asama] = (totals[asama] ?? 0) + adet;
    }
    return totals;
  }

  String? _sonGerceklesenTarihi() {
    if (maliyetGerceklesen.isEmpty) return null;
    DateTime? latest;
    for (final kayit in maliyetGerceklesen.whereType<Map>()) {
      final parsed = DateTime.tryParse(kayit['tarih']?.toString() ?? '');
      if (parsed == null) continue;
      if (latest == null || parsed.isAfter(latest)) latest = parsed;
    }
    return latest == null
        ? null
        : 'Son kayıt ${DateFormat('dd.MM.yyyy').format(latest)}';
  }

  List<String> _kalemTipiSecenekleri(ModelKarlilikOzeti ozet) {
    final values = ozet.kalemler.map((kalem) => kalem.kod).toSet().toList();
    if (!values.contains('diger')) values.add('diger');
    return values;
  }

  String _kalemTipiEtiketi(dynamic value) {
    switch (value?.toString()) {
      case 'iplik':
        return 'İplik';
      case 'orgu':
        return 'Örgü';
      case 'dikim':
        return 'Dikim';
      case 'utu':
        return 'Ütü';
      case 'yikama':
        return 'Yıkama';
      case 'ilik_dugme':
        return 'İlik Düğme';
      case 'fermuar':
        return 'Fermuar';
      case 'baski_nakis':
        return 'Baskı / Nakış';
      case 'aksesuar':
        return 'Model Aksesuarı';
      case 'genel_aksesuar':
        return 'Genel Aksesuar';
      case 'genel_gider':
        return 'Genel Gider';
      case 'paketleme':
        return 'Paketleme';
      default:
        return 'Diğer';
    }
  }

  String _asamaEtiketi(String value) {
    switch (value) {
      case 'model':
        return 'Model kartı';
      case 'sevkiyat':
        return 'Sevkiyat';
      case 'yukleme':
        return 'Yükleme';
      case 'depolama':
        return 'Depolama';
      case 'paketleme':
        return 'Paketleme';
      case 'kalite_kontrol':
        return 'Kalite kontrol';
      case 'kalite':
        return 'Kalite';
      case 'test':
        return 'Test';
      case 'utu':
      case 'utu_pres':
        return 'Ütü';
      case 'ilik_dugme':
        return 'İlik düğme';
      case 'yikama':
        return 'Yıkama';
      case 'nakis':
        return 'Nakış';
      case 'baski':
        return 'Baskı';
      case 'konfeksiyon':
        return 'Konfeksiyon';
      case 'dikim':
        return 'Dikim';
      case 'kesim':
        return 'Kesim';
      case 'orgu':
      case 'orme':
      case 'dokuma':
        return 'Örgü/Dokuma';
      default:
        return value == '-' ? 'Üretim yok' : value;
    }
  }

  String _tarihMetni(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  int _intDeger(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleDeger(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    final text = (value?.toString() ?? '').trim();
    if (text.contains(',')) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
    return double.tryParse(text) ?? 0;
  }
}

class _KpiData {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const _KpiData(
      this.label, this.value, this.description, this.icon, this.color);
}

class _KarlilikDurumu {
  final String label;
  final IconData icon;
  final Color color;

  const _KarlilikDurumu(this.label, this.icon, this.color);
}

class _DenetimSatiri {
  final String gosterge;
  final String kaynak;
  final String formul;
  final String kullanilanDeger;
  final String not;
  final bool uyari;

  const _DenetimSatiri({
    required this.gosterge,
    required this.kaynak,
    required this.formul,
    required this.kullanilanDeger,
    required this.not,
    required this.uyari,
  });
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF455A64),
      ),
    );
  }
}
