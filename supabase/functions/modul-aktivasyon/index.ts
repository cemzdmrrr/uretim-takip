// Modül Aktivasyon Edge Function
// Firma için modül ekleme/çıkarma işlemlerini yönetir.
// Abonelik planına göre modül limiti kontrolü yapar.

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

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const body = await req.json();
    const { firma_id, modul_kodu, islem } = body; // islem: "aktif" | "pasif"

    if (!firma_id || !modul_kodu || !islem) {
      return new Response(
        JSON.stringify({ error: "firma_id, modul_kodu ve islem (aktif/pasif) zorunlu" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Platform admin veya firma sahibi kontrolü
    const { data: platformRole } = await supabaseAdmin
      .from("user_roles")
      .select("role")
      .eq("user_id", user.id)
      .single();

    const isPlatformAdmin = platformRole?.role === "admin";

    if (!isPlatformAdmin) {
      const { data: firmaKullanici } = await supabaseAdmin
        .from("firma_kullanicilari")
        .select("rol")
        .eq("firma_id", firma_id)
        .eq("user_id", user.id)
        .eq("aktif", true)
        .single();

      if (!firmaKullanici || firmaKullanici.rol !== "firma_sahibi") {
        return new Response(
          JSON.stringify({ error: "Bu işlem için yetkiniz yok" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Modül tanımı kontrolü
    const { data: modul } = await supabaseAdmin
      .from("modul_tanimlari")
      .select("*")
      .eq("kod", modul_kodu)
      .single();

    if (!modul) {
      return new Response(
        JSON.stringify({ error: `Modül bulunamadı: ${modul_kodu}` }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (islem === "aktif") {
      // Abonelik planına göre modül limiti kontrolü
      const { data: abonelik } = await supabaseAdmin
        .from("firma_abonelikleri")
        .select("*, abonelik_planlari(*)")
        .eq("firma_id", firma_id)
        .in("durum", ["aktif", "deneme"])
        .order("created_at", { ascending: false })
        .limit(1)
        .single();

      if (abonelik) {
        const plan = abonelik.abonelik_planlari;
        const dahilModuller: string[] = plan?.dahil_moduller || [];

        // Plan sınırsız değilse ve modül dahil modüllerde değilse
        if (dahilModuller.length > 0 && !dahilModuller.includes(modul_kodu)) {
          // Mevcut aktif modül sayısını kontrol et
          const { count } = await supabaseAdmin
            .from("firma_modulleri")
            .select("*", { count: "exact", head: true })
            .eq("firma_id", firma_id)
            .eq("aktif", true);

          const maxModul = plan?.max_modul || 999;
          if ((count || 0) >= maxModul) {
            return new Response(
              JSON.stringify({
                error: `Abonelik planınız maksimum ${maxModul} modüle izin veriyor`,
              }),
              { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
        }
      }

      // Modülü aktifleştir (upsert)
      const { error: upsertError } = await supabaseAdmin
        .from("firma_modulleri")
        .upsert(
          { firma_id, modul_kodu, aktif: true },
          { onConflict: "firma_id,modul_kodu" }
        );

      if (upsertError) {
        return new Response(
          JSON.stringify({ error: `Modül aktifleştirilemedi: ${upsertError.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await supabaseAdmin.from("platform_loglari").insert({
        islem: "modul_aktif",
        detay: JSON.stringify({ firma_id, modul_kodu, user_id: user.id }),
        seviye: "info",
      });

      return new Response(
        JSON.stringify({ success: true, modul_kodu, durum: "aktif" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (islem === "pasif") {
      const { error: updateError } = await supabaseAdmin
        .from("firma_modulleri")
        .update({ aktif: false })
        .eq("firma_id", firma_id)
        .eq("modul_kodu", modul_kodu);

      if (updateError) {
        return new Response(
          JSON.stringify({ error: `Modül deaktif edilemedi: ${updateError.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await supabaseAdmin.from("platform_loglari").insert({
        islem: "modul_pasif",
        detay: JSON.stringify({ firma_id, modul_kodu, user_id: user.id }),
        seviye: "info",
      });

      return new Response(
        JSON.stringify({ success: true, modul_kodu, durum: "pasif" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "islem 'aktif' veya 'pasif' olmalı" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Beklenmeyen hata: ${(err as Error).message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
