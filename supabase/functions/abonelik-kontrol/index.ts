// Abonelik Kontrol Edge Function
// Periyodik olarak (cron ile) tüm abonelikleri kontrol eder.
// Süresi dolan denemeleri pasife alır, ödeme tarihi geçenleri uyarır.

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
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const now = new Date().toISOString();
    const sonuclar: Record<string, number> = {
      deneme_suresi_dolan: 0,
      odeme_geciken: 0,
    };

    // 1. Deneme süresi dolan abonelikleri pasife al
    const { data: suresiDolanlar } = await supabaseAdmin
      .from("firma_abonelikleri")
      .select("id, firma_id")
      .eq("durum", "deneme")
      .lt("deneme_bitis", now);

    if (suresiDolanlar && suresiDolanlar.length > 0) {
      const ids = suresiDolanlar.map((a: { id: string }) => a.id);
      await supabaseAdmin
        .from("firma_abonelikleri")
        .update({ durum: "pasif" })
        .in("id", ids);

      sonuclar.deneme_suresi_dolan = suresiDolanlar.length;

      // Bildirim oluştur
      for (const abonelik of suresiDolanlar) {
        await supabaseAdmin.from("bildirimler").insert({
          firma_id: abonelik.firma_id,
          baslik: "Deneme Süresi Doldu",
          mesaj: "Deneme süreniz sona erdi. Kullanmaya devam etmek için lütfen bir plan seçin.",
          tip: "uyari",
        });
      }
    }

    // 2. Ödeme tarihi geçen aktif abonelikleri kontrol et
    const { data: odemeGecikenler } = await supabaseAdmin
      .from("firma_abonelikleri")
      .select("id, firma_id")
      .eq("durum", "aktif")
      .lt("sonraki_odeme_tarihi", now);

    if (odemeGecikenler && odemeGecikenler.length > 0) {
      // Ödeme bekleniyor durumuna al
      const ids = odemeGecikenler.map((a: { id: string }) => a.id);
      await supabaseAdmin
        .from("firma_abonelikleri")
        .update({ durum: "odeme_bekleniyor" })
        .in("id", ids);

      sonuclar.odeme_geciken = odemeGecikenler.length;

      // Bildirim oluştur
      for (const abonelik of odemeGecikenler) {
        await supabaseAdmin.from("bildirimler").insert({
          firma_id: abonelik.firma_id,
          baslik: "Ödeme Hatırlatması",
          mesaj: "Abonelik ödemeniz gecikmiştir. Hizmet kesintisini önlemek için lütfen ödemenizi yapın.",
          tip: "uyari",
        });
      }
    }

    // 3. Platform loguna kaydet
    await supabaseAdmin.from("platform_loglari").insert({
      islem: "abonelik_kontrol",
      detay: JSON.stringify(sonuclar),
      seviye: "info",
    });

    return new Response(
      JSON.stringify({
        success: true,
        tarih: now,
        sonuclar,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Beklenmeyen hata: ${(err as Error).message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
