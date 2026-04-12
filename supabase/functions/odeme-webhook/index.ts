// Ödeme Webhook Edge Function
// Ödeme sağlayıcısından (iyzico/Stripe) gelen webhook'ları işler.
// Aboneliği aktifleştirir, ödeme kaydı oluşturur.

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

    const body = await req.json();
    const { event_type, firma_id, abonelik_id, tutar, odeme_yontemi, odeme_referans } = body;

    // Webhook imza doğrulaması
    // NOT: Gerçek entegrasyonda iyzico/Stripe imza doğrulaması yapılmalıdır.
    // const webhookSecret = Deno.env.get("PAYMENT_WEBHOOK_SECRET");
    // const signature = req.headers.get("x-webhook-signature");

    if (!event_type || !firma_id) {
      return new Response(
        JSON.stringify({ error: "event_type ve firma_id zorunlu" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const now = new Date();

    if (event_type === "payment.success") {
      // 1. Ödeme kaydı oluştur
      await supabaseAdmin.from("abonelik_odemeleri").insert({
        firma_id,
        abonelik_id,
        tutar: tutar || 0,
        odeme_yontemi: odeme_yontemi || "online",
        odeme_referans,
        durum: "basarili",
      });

      // 2. Aboneliği aktifleştir
      if (abonelik_id) {
        await supabaseAdmin
          .from("firma_abonelikleri")
          .update({
            durum: "aktif",
            baslangic_tarihi: now.toISOString(),
            son_odeme_tarihi: now.toISOString(),
            sonraki_odeme_tarihi: new Date(
              now.getTime() + 30 * 24 * 60 * 60 * 1000
            ).toISOString(),
          })
          .eq("id", abonelik_id);
      }

      // 3. Bildirim oluştur
      await supabaseAdmin.from("bildirimler").insert({
        firma_id,
        baslik: "Ödeme Başarılı",
        mesaj: `${tutar} TL tutarında ödemeniz başarıyla alındı.`,
        tip: "bilgi",
      });

      // 4. Platform log
      await supabaseAdmin.from("platform_loglari").insert({
        islem: "odeme_basarili",
        detay: JSON.stringify({ firma_id, abonelik_id, tutar, odeme_referans }),
        seviye: "info",
      });

      return new Response(
        JSON.stringify({ success: true, event: "payment.success" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (event_type === "payment.failed") {
      await supabaseAdmin.from("abonelik_odemeleri").insert({
        firma_id,
        abonelik_id,
        tutar: tutar || 0,
        odeme_yontemi: odeme_yontemi || "online",
        odeme_referans,
        durum: "basarisiz",
      });

      await supabaseAdmin.from("bildirimler").insert({
        firma_id,
        baslik: "Ödeme Başarısız",
        mesaj: "Ödeme işleminiz başarısız oldu. Lütfen tekrar deneyin.",
        tip: "hata",
      });

      await supabaseAdmin.from("platform_loglari").insert({
        islem: "odeme_basarisiz",
        detay: JSON.stringify({ firma_id, abonelik_id, tutar, odeme_referans }),
        seviye: "warning",
      });

      return new Response(
        JSON.stringify({ success: true, event: "payment.failed" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: `Bilinmeyen event_type: ${event_type}` }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Beklenmeyen hata: ${(err as Error).message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
