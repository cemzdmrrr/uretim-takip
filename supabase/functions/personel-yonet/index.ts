import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function kolonEksikHatasi(error: { code?: string; message?: string } | null) {
  if (!error) return false;
  const hata = `${error.code ?? ""} ${error.message ?? ""}`.toLowerCase();
  return error.code === "42703" || hata.includes("does not exist");
}

async function updatePersonelKaydi(
  supabaseAdmin: ReturnType<typeof createClient>,
  firmaId: string,
  userId: string,
  payload: Record<string, unknown>,
) {
  const { error } = await supabaseAdmin
    .from("personel")
    .update(payload)
    .eq("firma_id", firmaId)
    .eq("user_id", userId);

  if (!kolonEksikHatasi(error)) {
    return error;
  }

  const fallbackPayload: Record<string, unknown> = {};
  if (payload["durum"] != null) {
    fallbackPayload["durum"] = payload["durum"];
  }

  const { error: fallbackError } = await supabaseAdmin
    .from("personel")
    .update(fallbackPayload)
    .eq("firma_id", firmaId)
    .eq("user_id", userId);

  return fallbackError;
}

async function bestEffortDelete(
  supabaseAdmin: ReturnType<typeof createClient>,
  table: string,
  column: string,
  value: string,
) {
  const { error } = await supabaseAdmin.from(table).delete().eq(column, value);
  if (!error) return;

  const hata = `${error.code ?? ""} ${error.message ?? ""}`.toLowerCase();
  if (
    error.code === "42P01" ||
    error.code === "PGRST204" ||
    hata.includes("does not exist") ||
    hata.includes("schema cache")
  ) {
    return;
  }

  throw new Error(`${table} silinemedi: ${error.message}`);
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

    const body = await req.json().catch(() => null);
    const action = body?.action?.toString().trim();
    const firmaId = body?.firma_id?.toString().trim();
    const userId = body?.user_id?.toString().trim();
    const tckn = body?.tckn?.toString().trim();
    const neden = body?.neden?.toString().trim() ?? "";
    const cikisTarihi =
      body?.cikis_tarihi?.toString().trim() ||
      new Date().toISOString().slice(0, 10);

    if (!action || !firmaId || !userId || !tckn) {
      return jsonResponse(
        { error: "action, firma_id, user_id ve tckn zorunlu" },
        400,
      );
    }

    const [{ data: platformRole }, { data: firmaRole }] = await Promise.all([
      supabaseAdmin
        .from("user_roles")
        .select("role")
        .eq("user_id", user.id)
        .eq("aktif", true)
        .maybeSingle(),
      supabaseAdmin
        .from("firma_kullanicilari")
        .select("rol")
        .eq("firma_id", firmaId)
        .eq("user_id", user.id)
        .eq("aktif", true)
        .maybeSingle(),
    ]);

    const isPlatformAdmin = platformRole?.role === "admin";
    const isFirmaAdmin =
      firmaRole?.rol === "firma_sahibi" || firmaRole?.rol === "firma_admin";

    if (!isPlatformAdmin && !isFirmaAdmin) {
      return jsonResponse({ error: "Bu islem icin yetkiniz yok" }, 403);
    }

    const { data: personel, error: personelError } = await supabaseAdmin
      .from("personel")
      .select("user_id, firma_id, ad, soyad, email, durum")
      .eq("firma_id", firmaId)
      .eq("user_id", userId)
      .eq("tckn", tckn)
      .maybeSingle();

    if (personelError) {
      return jsonResponse(
        { error: `Personel kaydi okunamadi: ${personelError.message}` },
        500,
      );
    }

    if (!personel) {
      return jsonResponse({ error: "Personel bulunamadi" }, 404);
    }

    if (action === "isten_cikar") {
      if (!neden) {
        return jsonResponse({ error: "Isten cikarma nedeni zorunlu" }, 400);
      }

      const personelGuncelleError = await updatePersonelKaydi(
        supabaseAdmin,
        firmaId,
        userId,
        {
          durum: "isten_cikarildi",
          isten_cikis_tarihi: cikisTarihi,
          isten_cikis_nedeni: neden,
          silme_tarihi: new Date().toISOString(),
        },
      );

      if (personelGuncelleError) {
        return jsonResponse(
          { error: `Personel guncellenemedi: ${personelGuncelleError.message}` },
          500,
        );
      }

      await supabaseAdmin
        .from("firma_kullanicilari")
        .update({ aktif: false })
        .eq("firma_id", firmaId)
        .eq("user_id", userId);

      await supabaseAdmin
        .from("kullanici_aktif_firma")
        .delete()
        .eq("firma_id", firmaId)
        .eq("user_id", userId);

      const { count: aktifFirmaSayisi } = await supabaseAdmin
        .from("firma_kullanicilari")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("aktif", true);

      if ((aktifFirmaSayisi ?? 0) == 0) {
        await supabaseAdmin
          .from("user_roles")
          .update({ aktif: false })
          .eq("user_id", userId)
          .eq("role", "personel");
      }

      return jsonResponse({
        success: true,
        action,
        durum: "isten_cikarildi",
        user_id: userId,
      });
    }

    if (action === "aktif_yap") {
      const personelAktifError = await updatePersonelKaydi(
        supabaseAdmin,
        firmaId,
        userId,
        {
          durum: "aktif",
          isten_cikis_tarihi: null,
          isten_cikis_nedeni: null,
          silme_tarihi: null,
        },
      );

      if (personelAktifError) {
        return jsonResponse(
          { error: `Personel guncellenemedi: ${personelAktifError.message}` },
          500,
        );
      }

      await supabaseAdmin.from("firma_kullanicilari").upsert(
        {
          firma_id: firmaId,
          user_id: userId,
          rol: "personel",
          aktif: true,
        },
        { onConflict: "firma_id,user_id" },
      );

      await supabaseAdmin.from("user_roles").upsert(
        {
          user_id: userId,
          role: "personel",
          aktif: true,
        },
        { onConflict: "user_id" },
      );

      await supabaseAdmin.from("kullanici_aktif_firma").upsert(
        {
          user_id: userId,
          firma_id: firmaId,
        },
        { onConflict: "user_id" },
      );

      return jsonResponse({
        success: true,
        action,
        durum: "aktif",
        user_id: userId,
      });
    }

    if (action === "kalici_sil") {
      await supabaseAdmin
        .from("firma_kullanicilari")
        .delete()
        .eq("firma_id", firmaId)
        .eq("user_id", userId);

      await supabaseAdmin
        .from("kullanici_aktif_firma")
        .delete()
        .eq("firma_id", firmaId)
        .eq("user_id", userId);

      const { error: personelSilmeError } = await supabaseAdmin
        .from("personel")
        .delete()
        .eq("firma_id", firmaId)
        .eq("user_id", userId);

      if (personelSilmeError) {
        return jsonResponse(
          { error: `Personel silinemedi: ${personelSilmeError.message}` },
          500,
        );
      }

      const [{ count: firmaBagSayisi }, { data: rol }] = await Promise.all([
        supabaseAdmin
          .from("firma_kullanicilari")
          .select("id", { count: "exact", head: true })
          .eq("user_id", userId),
        supabaseAdmin
          .from("user_roles")
          .select("role")
          .eq("user_id", userId)
          .maybeSingle(),
      ]);

      if ((firmaBagSayisi ?? 0) == 0 && rol?.role === "personel") {
        await bestEffortDelete(supabaseAdmin, "user_roles", "user_id", userId);
        await bestEffortDelete(supabaseAdmin, "users", "id", userId);
        const { error: authSilmeError } = await supabaseAdmin.auth.admin.deleteUser(
          userId,
        );
        if (authSilmeError) {
          return jsonResponse(
            { error: `Auth kullanicisi silinemedi: ${authSilmeError.message}` },
            500,
          );
        }
      }

      return jsonResponse({
        success: true,
        action,
        user_id: userId,
      });
    }

    return jsonResponse({ error: "Gecersiz action" }, 400);
  } catch (error) {
    return jsonResponse(
      { error: `Beklenmeyen hata: ${(error as Error).message}` },
      500,
    );
  }
});
