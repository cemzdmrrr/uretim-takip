// Kullanıcı Davet Edge Function
// Davet kodu oluşturur ve e-posta gönderir.
// Service role key client'ta tutulmaz.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  const array = new Uint8Array(8);
  crypto.getRandomValues(array);
  for (const byte of array) {
    code += chars[byte % chars.length];
  }
  return code;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
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
    const { email, rol, firma_id } = body;

    if (!email || !firma_id) {
      return new Response(
        JSON.stringify({ error: "email ve firma_id zorunlu" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Kullanıcının bu firmada yetkili olup olmadığını kontrol et
    const { data: firmaKullanici } = await supabaseAdmin
      .from("firma_kullanicilari")
      .select("rol")
      .eq("firma_id", firma_id)
      .eq("user_id", user.id)
      .eq("aktif", true)
      .maybeSingle();

    if (!firmaKullanici || !["firma_sahibi", "firma_admin"].includes(firmaKullanici.rol)) {
      return new Response(
        JSON.stringify({ error: "Bu işlem için yetkiniz yok" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Davet kodu oluştur
    const davetKodu = generateInviteCode();

    const { error: davetError } = await supabaseAdmin
      .from("firma_davetleri")
      .insert({
        firma_id,
        davet_eden_id: user.id,
        email,
        rol: rol || "kullanici",
        davet_kodu: davetKodu,
        durum: "beklemede",
      });

    if (davetError) {
      return new Response(
        JSON.stringify({ error: `Davet oluşturma hatası: ${davetError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Firma adını al (e-posta için)
    const { data: firma } = await supabaseAdmin
      .from("firmalar")
      .select("firma_adi")
      .eq("id", firma_id)
      .single();

    // E-posta gönderimi (Supabase Auth ile veya harici servis ile)
    // NOT: Gerçek e-posta entegrasyonu için SMTP veya SendGrid/Resend gibi
    // bir servis yapılandırılmalıdır.
    const appUrl = Deno.env.get("APP_URL") || "https://texpilot.com";
    const davetUrl = `${appUrl}/onboarding/davet_katil?kod=${davetKodu}`;

    // Loglama
    console.log(`Davet oluşturuldu: ${email} -> ${firma?.firma_adi} (kod: ${davetKodu})`);

    return new Response(
      JSON.stringify({
        success: true,
        davet_kodu: davetKodu,
        davet_url: davetUrl,
        firma_adi: firma?.firma_adi,
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
