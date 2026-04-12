// Platform Rapor Edge Function
// Platform genelinde istatistik hesaplar ve döndürür.
// Platform admin paneli tarafından çağrılır.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Kullanıcı doğrulama
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Yetkilendirme gerekli" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Geçersiz oturum" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Platform admin kontrolü
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: platformRole } = await supabaseAdmin
      .from("user_roles")
      .select("role")
      .eq("user_id", user.id)
      .single();

    if (!platformRole || platformRole.role !== "admin") {
      return new Response(
        JSON.stringify({ error: "Platform admin yetkisi gerekli" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const url = new URL(req.url);
    const raporTipi = url.searchParams.get("tip") || "genel";

    if (raporTipi === "genel") {
      // Genel platform istatistikleri
      const [
        firmaRes,
        kullaniciRes,
        aktifAbonelikRes,
        denemeAbonelikRes,
        destekRes,
      ] = await Promise.all([
        supabaseAdmin.from("firmalar").select("*", { count: "exact", head: true }),
        supabaseAdmin.from("firma_kullanicilari").select("*", { count: "exact", head: true }).eq("aktif", true),
        supabaseAdmin.from("firma_abonelikleri").select("*", { count: "exact", head: true }).eq("durum", "aktif"),
        supabaseAdmin.from("firma_abonelikleri").select("*", { count: "exact", head: true }).eq("durum", "deneme"),
        supabaseAdmin.from("destek_talepleri").select("*", { count: "exact", head: true }).eq("durum", "acik"),
      ]);

      // Son 30 gün ödeme toplamı
      const otuzGunOnce = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
      const { data: odemeler } = await supabaseAdmin
        .from("abonelik_odemeleri")
        .select("tutar")
        .eq("durum", "basarili")
        .gte("created_at", otuzGunOnce);

      const toplamGelir = (odemeler || []).reduce(
        (sum: number, o: { tutar: number }) => sum + (o.tutar || 0),
        0
      );

      // Modül kullanım dağılımı
      const { data: modulKullanim } = await supabaseAdmin
        .from("firma_modulleri")
        .select("modul_kodu")
        .eq("aktif", true);

      const modulDagilim: Record<string, number> = {};
      (modulKullanim || []).forEach((m: { modul_kodu: string }) => {
        modulDagilim[m.modul_kodu] = (modulDagilim[m.modul_kodu] || 0) + 1;
      });

      return new Response(
        JSON.stringify({
          rapor_tipi: "genel",
          tarih: new Date().toISOString(),
          toplam_firma: firmaRes.count || 0,
          aktif_kullanici: kullaniciRes.count || 0,
          aktif_abonelik: aktifAbonelikRes.count || 0,
          deneme_abonelik: denemeAbonelikRes.count || 0,
          acik_destek_talebi: destekRes.count || 0,
          son_30_gun_gelir: toplamGelir,
          modul_kullanim_dagilimi: modulDagilim,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (raporTipi === "firma-detay") {
      const firmaId = url.searchParams.get("firma_id");
      if (!firmaId) {
        return new Response(
          JSON.stringify({ error: "firma_id parametresi gerekli" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const [firmaRes, kullaniciRes, modulRes, abonelikRes] = await Promise.all([
        supabaseAdmin.from("firmalar").select("*").eq("id", firmaId).single(),
        supabaseAdmin.from("firma_kullanicilari").select("user_id, rol, aktif").eq("firma_id", firmaId),
        supabaseAdmin.from("firma_modulleri").select("modul_kodu, aktif").eq("firma_id", firmaId),
        supabaseAdmin.from("firma_abonelikleri").select("*, abonelik_planlari(ad, kod)").eq("firma_id", firmaId).order("created_at", { ascending: false }).limit(1),
      ]);

      return new Response(
        JSON.stringify({
          rapor_tipi: "firma-detay",
          firma: firmaRes.data,
          kullanicilar: kullaniciRes.data || [],
          moduller: modulRes.data || [],
          abonelik: (abonelikRes.data || [])[0] || null,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (raporTipi === "gelir") {
      const gun = parseInt(url.searchParams.get("gun") || "30");
      const baslangic = new Date(Date.now() - gun * 24 * 60 * 60 * 1000).toISOString();

      const { data: odemeler } = await supabaseAdmin
        .from("abonelik_odemeleri")
        .select("tutar, odeme_yontemi, durum, created_at")
        .gte("created_at", baslangic)
        .order("created_at", { ascending: false });

      const basarili = (odemeler || []).filter((o: { durum: string }) => o.durum === "basarili");
      const toplamGelir = basarili.reduce(
        (sum: number, o: { tutar: number }) => sum + (o.tutar || 0),
        0
      );

      return new Response(
        JSON.stringify({
          rapor_tipi: "gelir",
          donem_gun: gun,
          toplam_odeme: (odemeler || []).length,
          basarili_odeme: basarili.length,
          toplam_gelir: toplamGelir,
          odemeler: odemeler || [],
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: `Bilinmeyen rapor tipi: ${raporTipi}. Geçerli tipler: genel, firma-detay, gelir` }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Beklenmeyen hata: ${(err as Error).message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
