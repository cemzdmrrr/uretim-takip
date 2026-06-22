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

async function usersTableUpsert(
  supabaseAdmin: ReturnType<typeof createClient>,
  userId: string,
  email: string,
) {
  const { error } = await supabaseAdmin.from("users").upsert(
    {
      id: userId,
      email,
      role: "personel",
    },
    { onConflict: "id" },
  );

  if (!error) return;

  const hata = `${error.code ?? ""} ${error.message ?? ""}`.toLowerCase();
  if (
    error.code === "42P01" ||
    error.code === "PGRST204" ||
    hata.includes("schema cache") ||
    hata.includes("relation") ||
    hata.includes("does not exist")
  ) {
    return;
  }

  throw new Error(`users tablosu guncellenemedi: ${error.message}`);
}

async function kullaniciPlatformAdminMi(
  supabaseAdmin: ReturnType<typeof createClient>,
  userId: string,
) {
  const { data, error } = await supabaseAdmin
    .from("user_roles")
    .select("role")
    .eq("user_id", userId)
    .eq("aktif", true);

  if (error) {
    throw new Error(`Rol kontrolu yapilamadi: ${error.message}`);
  }

  return (data ?? []).some((row: { role?: string }) => row.role === "admin");
}

async function personelRolunuAktiflestir(
  supabaseAdmin: ReturnType<typeof createClient>,
  userId: string,
  firmaId: string,
) {
  const { data: mevcut, error: mevcutError } = await supabaseAdmin
    .from("user_roles")
    .select("id")
    .eq("user_id", userId)
    .eq("firma_id", firmaId)
    .eq("role", "personel")
    .maybeSingle();

  if (mevcutError) {
    throw new Error(`user_roles kontrol edilemedi: ${mevcutError.message}`);
  }

  if (mevcut?.id != null) {
    const { error } = await supabaseAdmin
      .from("user_roles")
      .update({ aktif: true })
      .eq("id", mevcut.id);

    if (error) {
      throw new Error(`user_roles kaydi guncellenemedi: ${error.message}`);
    }
    return;
  }

  const { error } = await supabaseAdmin.from("user_roles").insert({
    user_id: userId,
    firma_id: firmaId,
    role: "personel",
    aktif: true,
  });

  if (error) {
    throw new Error(`user_roles kaydi olusturulamadi: ${error.message}`);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let olusanUserId: string | null = null;

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
    const firmaId = body?.firma_id?.toString().trim();
    const email = body?.email?.toString().trim().toLowerCase();
    const password = body?.password?.toString() ?? "";
    const ad = body?.ad?.toString().trim();
    const soyad = body?.soyad?.toString().trim();
    const tckn = body?.tckn?.toString().trim();

    if (!firmaId || !email || !password || !ad || !soyad || !tckn) {
      return jsonResponse(
        { error: "firma_id, email, password, ad, soyad ve tckn zorunlu" },
        400,
      );
    }

    if (password.length < 6) {
      return jsonResponse({ error: "Parola en az 6 karakter olmali" }, 400);
    }

    const [{ data: firmaRole }, isPlatformAdmin] = await Promise.all([
      supabaseAdmin
        .from("firma_kullanicilari")
        .select("rol")
        .eq("firma_id", firmaId)
        .eq("user_id", user.id)
        .eq("aktif", true)
        .maybeSingle(),
      kullaniciPlatformAdminMi(supabaseAdmin, user.id),
    ]);

    const isFirmaAdmin =
      firmaRole?.rol === "firma_sahibi" || firmaRole?.rol === "firma_admin";

    if (!isPlatformAdmin && !isFirmaAdmin) {
      return jsonResponse({ error: "Bu islem icin yetkiniz yok" }, 403);
    }

    const { data: mevcutTckn } = await supabaseAdmin
      .from("personel")
      .select("user_id")
      .eq("firma_id", firmaId)
      .eq("tckn", tckn)
      .maybeSingle();

    if (mevcutTckn) {
      return jsonResponse(
        { error: "Bu TCKN ile kayitli personel zaten var" },
        409,
      );
    }

    const { data: olusanUser, error: createUserError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          ad,
          soyad,
          display_name: `${ad} ${soyad}`.trim(),
        },
      });

    if (createUserError || !olusanUser.user) {
      const hataMesaji =
        createUserError?.message ?? "Kullanici olusturulamadi";
      return jsonResponse({ error: hataMesaji }, 409);
    }

    olusanUserId = olusanUser.user.id;

    const personelKaydi = {
      firma_id: firmaId,
      user_id: olusanUserId,
      ad,
      soyad,
      tckn,
      pozisyon: body?.pozisyon?.toString().trim() || "",
      departman: body?.departman?.toString().trim() || "",
      email,
      telefon: body?.telefon?.toString().trim() || "",
      ise_baslangic: body?.ise_baslangic ?? null,
      brut_maas: body?.brut_maas ?? null,
      sgk_sicil_no: body?.sgk_sicil_no?.toString().trim() || "",
      gunluk_calisma_saati: body?.gunluk_calisma_saati ?? null,
      haftalik_calisma_gunu: body?.haftalik_calisma_gunu ?? null,
      yol_ucreti: body?.yol_ucreti ?? null,
      yemek_ucreti: body?.yemek_ucreti ?? null,
      ekstra_prim: body?.ekstra_prim ?? null,
      elden_maas: body?.elden_maas ?? 0,
      banka_maas: body?.banka_maas ?? null,
      adres: body?.adres?.toString().trim() || "",
      net_maas: body?.net_maas ?? null,
      yillik_izin_hakki: body?.yillik_izin_hakki ?? null,
      durum: "aktif",
    };

    await personelRolunuAktiflestir(supabaseAdmin, olusanUserId, firmaId);

    const { error: firmaKullaniciError } = await supabaseAdmin
      .from("firma_kullanicilari")
      .upsert(
        {
          firma_id: firmaId,
          user_id: olusanUserId,
          rol: "personel",
          aktif: true,
        },
        { onConflict: "firma_id,user_id" },
      );

    if (firmaKullaniciError) {
      throw new Error(
        `firma_kullanicilari kaydi olusturulamadi: ${firmaKullaniciError.message}`,
      );
    }

    await supabaseAdmin.from("kullanici_aktif_firma").upsert(
      { user_id: olusanUserId, firma_id: firmaId },
      { onConflict: "user_id" },
    );

    await usersTableUpsert(supabaseAdmin, olusanUserId, email);

    const { data: personel, error: personelError } = await supabaseAdmin
      .from("personel")
      .insert(personelKaydi)
      .select()
      .single();

    if (personelError) {
      throw new Error(`personel kaydi olusturulamadi: ${personelError.message}`);
    }

    return jsonResponse({
      success: true,
      user_id: olusanUserId,
      personel,
    });
  } catch (error) {
    if (olusanUserId != null) {
      const supabaseAdmin = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      );

      await Promise.allSettled([
        supabaseAdmin.from("personel").delete().eq("user_id", olusanUserId),
        supabaseAdmin
          .from("firma_kullanicilari")
          .delete()
          .eq("user_id", olusanUserId),
        supabaseAdmin.from("user_roles").delete().eq("user_id", olusanUserId),
        supabaseAdmin
          .from("kullanici_aktif_firma")
          .delete()
          .eq("user_id", olusanUserId),
        supabaseAdmin.auth.admin.deleteUser(olusanUserId),
      ]);
    }

    return jsonResponse(
      { error: `Beklenmeyen hata: ${(error as Error).message}` },
      500,
    );
  }
});
