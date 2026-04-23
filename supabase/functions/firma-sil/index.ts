import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const firmaBagimliTablolar = [
  "iplik_stok_hareketleri",
  "iplik_hareketleri",
  "iplik_siparis_teslimatlar",
  "iplik_siparisleri",
  "aksesuar_kullanim",
  "stok_hareketleri",
  "kasa_banka_hareketleri",
  "odeme_gecmisi",
  "odeme_kayitlari",
  "fatura_kalemleri",
  "sevkiyat_detaylari",
  "ceki_listesi",
  "yukleme_kayitlari",
  "sevk_talepleri",
  "uretim_kayitlari",
  "uretim_atamalari",
  "dokuma_atamalari",
  "konfeksiyon_atamalari",
  "kalite_kontrol_atamalari",
  "paketleme_atamalari",
  "utu_atamalari",
  "yikama_atamalari",
  "nakis_atamalari",
  "ilik_dugme_atamalari",
  "atama_istatistikleri",
  "model_kritikleri",
  "model_toplam_adetler",
  "model_aksesuar",
  "teknik_dosyalar",
  "mesai_kayitlari",
  "izin_kayitlari",
  "personel_donem",
  "bordro",
  "puantaj",
  "mesai",
  "izinler",
  "destek_talepleri",
  "firma_sayfa_yetkileri",
  "rol_sayfa_yetkileri",
  "kullanici_sayfa_yetkileri",
  "kullanici_aktif_firma",
  "firma_davetleri",
  "firma_modulleri",
  "firma_uretim_modulleri",
  "abonelik_odemeleri",
  "firma_abonelikleri",
  "urun_depo",
  "aksesuar_stok",
  "aksesuarlar",
  "iplik_stoklari",
  "kasa_banka_hesaplari",
  "faturalar",
  "musteriler",
  "tedarikci_odemeleri",
  "tedarikci_siparisleri",
  "tedarikciler",
  "donemler",
  "personel",
  "atolyeler",
  "sirket_bilgileri",
  "triko_takip",
  "modeller",
  "firma_kullanicilari",
  "firma_ayarlari",
];

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function bestEffortDeleteByFirma(
  supabaseAdmin: ReturnType<typeof createClient>,
  table: string,
  firmaId: string,
) {
  const { error, count } = await supabaseAdmin
    .from(table)
    .delete({ count: "exact" })
    .eq("firma_id", firmaId);

  if (!error) {
    return count ?? 0;
  }

  const hataMesaji = `${error.code ?? ""} ${error.message ?? ""}`.toLowerCase();
  const yoksayilabilir =
    error.code === "42P01" ||
    error.code === "PGRST204" ||
    hataMesaji.includes("firma_id") ||
    hataMesaji.includes("column") ||
    hataMesaji.includes("schema cache");

  if (yoksayilabilir) {
    return 0;
  }

  throw new Error(`${table}: ${error.message}`);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Yetkilendirme gerekli" }, 401);
    }

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error: authError,
    } = await supabaseUser.auth.getUser();

    if (authError || !user) {
      return jsonResponse({ error: "Gecersiz oturum" }, 401);
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: kullaniciRol, error: rolError } = await supabaseAdmin
      .from("user_roles")
      .select("role")
      .eq("user_id", user.id)
      .maybeSingle();

    if (rolError) {
      return jsonResponse({ error: `Rol kontrolu basarisiz: ${rolError.message}` }, 500);
    }

    if (kullaniciRol?.role !== "admin") {
      return jsonResponse({ error: "Bu islem icin admin yetkisi gerekli" }, 403);
    }

    const body = await req.json().catch(() => null);
    const firmaId = body?.firma_id?.toString().trim();
    if (!firmaId) {
      return jsonResponse({ error: "firma_id zorunlu" }, 400);
    }

    const { data: firma, error: firmaError } = await supabaseAdmin
      .from("firmalar")
      .select("id, firma_adi, firma_kodu")
      .eq("id", firmaId)
      .maybeSingle();

    if (firmaError) {
      return jsonResponse({ error: `Firma okunamadi: ${firmaError.message}` }, 500);
    }

    if (!firma) {
      return jsonResponse({ error: "Firma bulunamadi" }, 404);
    }

    const { data: firmaKullanicilari, error: firmaKullanicilariError } =
      await supabaseAdmin
        .from("firma_kullanicilari")
        .select("user_id")
        .eq("firma_id", firmaId);

    if (firmaKullanicilariError) {
      return jsonResponse(
        { error: `Firma kullanicilari okunamadi: ${firmaKullanicilariError.message}` },
        500,
      );
    }

    const kullaniciIdleri = [
      ...new Set(
        (firmaKullanicilari ?? [])
          .map((kayit) => kayit.user_id?.toString())
          .filter((deger): deger is string => !!deger),
      ),
    ];

    let silinenKayitSayisi = 0;
    for (const table of firmaBagimliTablolar) {
      silinenKayitSayisi += await bestEffortDeleteByFirma(
        supabaseAdmin,
        table,
        firmaId,
      );
    }

    const { error: firmaSilmeError } = await supabaseAdmin
      .from("firmalar")
      .delete()
      .eq("id", firmaId);

    if (firmaSilmeError) {
      return jsonResponse(
        { error: `Firma silinemedi: ${firmaSilmeError.message}` },
        500,
      );
    }

    let silinenKullaniciSayisi = 0;
    for (const kullaniciId of kullaniciIdleri) {
      if (kullaniciId === user.id) {
        continue;
      }

      const [{ count: digerFirmaSayisi, error: digerFirmaError }, { data: rol }] =
        await Promise.all([
          supabaseAdmin
            .from("firma_kullanicilari")
            .select("id", { count: "exact", head: true })
            .eq("user_id", kullaniciId),
          supabaseAdmin
            .from("user_roles")
            .select("role")
            .eq("user_id", kullaniciId)
            .maybeSingle(),
        ]);

      if (digerFirmaError) {
        return jsonResponse(
          { error: `Kullanici firma baglari okunamadi: ${digerFirmaError.message}` },
          500,
        );
      }

      if ((digerFirmaSayisi ?? 0) > 0 || rol?.role === "admin") {
        continue;
      }

      const { error: kullaniciSilmeError } = await supabaseAdmin.auth.admin
        .deleteUser(kullaniciId);

      if (kullaniciSilmeError) {
        return jsonResponse(
          { error: `Kullanici silinemedi: ${kullaniciSilmeError.message}` },
          500,
        );
      }

      silinenKullaniciSayisi++;
    }

    await supabaseAdmin.from("platform_loglari").insert({
      islem_tipi: "firma_sil",
      hedef_tablo: "firmalar",
      hedef_id: firmaId,
      detay: {
        firma_adi: firma.firma_adi,
        firma_kodu: firma.firma_kodu,
        silinen_kayit_sayisi: silinenKayitSayisi,
        silinen_kullanici_sayisi: silinenKullaniciSayisi,
        islem_yapan: user.id,
      },
    });

    return jsonResponse({
      success: true,
      firma_id: firmaId,
      firma_adi: firma.firma_adi,
      silinen_kayit_sayisi: silinenKayitSayisi,
      silinen_kullanici_sayisi: silinenKullaniciSayisi,
    });
  } catch (error) {
    return jsonResponse(
      { error: `Beklenmeyen hata: ${(error as Error).message}` },
      500,
    );
  }
});
