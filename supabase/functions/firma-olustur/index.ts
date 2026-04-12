// Firma Oluşturma Edge Function
// Firma oluşturma işlemini sunucu tarafında transaction ile yapar.
// Client-side service role key ihtiyacını ortadan kaldırır.

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
    // JWT'den kullanıcı bilgisi al
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Authorization header gerekli" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Kullanıcıyı doğrula
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Geçersiz token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { firma_adi, firma_kodu, firma_bilgileri, secilen_moduller, secilen_uretim_dallari } = body;

    if (!firma_adi || !firma_kodu) {
      return new Response(
        JSON.stringify({ error: "firma_adi ve firma_kodu zorunlu" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Firma kodu müsait mi kontrol et
    const { data: existingFirma } = await supabaseAdmin
      .from("firmalar")
      .select("id")
      .eq("firma_kodu", firma_kodu)
      .maybeSingle();

    if (existingFirma) {
      return new Response(
        JSON.stringify({ error: "Bu firma kodu zaten kullanımda" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Firma oluştur
    const firmaData: Record<string, unknown> = {
      firma_adi,
      firma_kodu,
      ...(firma_bilgileri || {}),
    };

    const { data: firma, error: firmaError } = await supabaseAdmin
      .from("firmalar")
      .insert(firmaData)
      .select("id")
      .single();

    if (firmaError) {
      return new Response(
        JSON.stringify({ error: `Firma oluşturma hatası: ${firmaError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const firmaId = firma.id;

    // 3. Kullanıcıyı firma sahibi olarak ata
    await supabaseAdmin.from("firma_kullanicilari").insert({
      firma_id: firmaId,
      user_id: user.id,
      rol: "firma_sahibi",
      aktif: true,
      katilim_tarihi: new Date().toISOString(),
    });

    // 4. Aktif firma olarak ayarla
    await supabaseAdmin.from("kullanici_aktif_firma").upsert({
      user_id: user.id,
      firma_id: firmaId,
    });

    // 5. Tüm modülleri ata (deneme döneminde tüm modüller dahil)
    const { data: tumModuller } = await supabaseAdmin
      .from("modul_tanimlari")
      .select("id, modul_kodu");

    if (tumModuller && tumModuller.length > 0) {
      const modulKayitlari = tumModuller.map((m: { id: string }) => ({
        firma_id: firmaId,
        modul_id: m.id,
        aktif: true,
      }));
      await supabaseAdmin.from("firma_modulleri").upsert(modulKayitlari);
    }

    // 6. Üretim dallarını ata
    if (secilen_uretim_dallari && secilen_uretim_dallari.length > 0) {
      const { data: dallar } = await supabaseAdmin
        .from("uretim_modulleri")
        .select("id, modul_kodu")
        .in("modul_kodu", secilen_uretim_dallari);

      if (dallar && dallar.length > 0) {
        const dalKayitlari = dallar.map((d: { id: string }) => ({
          firma_id: firmaId,
          uretim_modul_id: d.id,
          aktif: true,
        }));
        await supabaseAdmin.from("firma_uretim_modulleri").upsert(dalKayitlari);
      }
    }

    // 7. Deneme aboneliği başlat
    const { data: denemePlan } = await supabaseAdmin
      .from("abonelik_planlari")
      .select("id")
      .eq("plan_kodu", "deneme")
      .maybeSingle();

    if (denemePlan) {
      await supabaseAdmin.from("firma_abonelikleri").insert({
        firma_id: firmaId,
        plan_id: denemePlan.id,
        durum: "deneme",
        odeme_periyodu: "aylik",
      });
    }

    return new Response(
      JSON.stringify({ firma_id: firmaId, success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Beklenmeyen hata: ${(err as Error).message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
