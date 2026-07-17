import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const uyumsoftEndpoint =
  Deno.env.get("UYUMSOFT_ENDPOINT") ??
  "https://edonusumapi.uyum.com.tr/Services/Integration";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const firmaId = body.firma_id as string | undefined;
    if (!firmaId) return json({ success: false, error: "firma_id zorunludur" }, 400);

    const username = Deno.env.get("UYUMSOFT_USERNAME");
    const password = Deno.env.get("UYUMSOFT_PASSWORD");
    const vkn = Deno.env.get("UYUMSOFT_VKN");
    if (!username || !password || !vkn) {
      return json({
        success: false,
        error:
          "Uyumsoft web servis secret bilgileri eksik. UYUMSOFT_USERNAME, UYUMSOFT_PASSWORD ve UYUMSOFT_VKN tanimlayin. Portal kullanicisi yerine Web Servis Kullanicisi kullanilmalidir.",
      }, 400);
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const now = new Date();
    const startDate = parseDate(body.baslangic_tarihi) ?? new Date(now);
    if (!body.baslangic_tarihi) {
      startDate.setDate(startDate.getDate() - Number(body.gun ?? 30));
    }
    const endDate = parseDate(body.bitis_tarihi) ?? now;
    const tarihTipi = normalizeTarihTipi(body.tarih_tipi);
    const limit = normalizeLimit(body.limit);

    const invoiceIds = await getInboxInvoiceIds(
      startDate,
      endDate,
      tarihTipi,
      limit,
      username,
      password,
    );

    let aktarilan = 0;
    const hatalar: string[] = [];

    for (const invoiceId of invoiceIds) {
      try {
        const dataXml = await soapCall(
          "GetInboxInvoiceData",
          `<tem:invoiceId>${escapeXml(invoiceId)}</tem:invoiceId>`,
          username,
          password,
        );
        let invoiceXml = extractInvoiceXml(dataXml);
        if (!invoiceXml) {
          assertSuccess(dataXml, "GetInboxInvoiceData");
          invoiceXml = extractInvoiceXml(dataXml);
        }
        if (!invoiceXml) {
          const preview = dataXml.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ")
            .trim().slice(0, 240);
          throw new Error(
            `Detay cevabinda UBL/XML data alani bulunamadi. Cevap: ${preview}`,
          );
        }
        const parsed = parseUblInvoice(invoiceXml);
        const ettn = parsed.ettn || invoiceId;
        const faturaNo = (parsed.faturaNo || invoiceId).trim();
        const mevcutFatura = await mevcutFaturaBul(
          supabaseAdmin,
          firmaId,
          faturaNo,
          ettn,
        );
        if (mevcutFatura) {
          await supabaseAdmin
            .from("uyumsoft_gelen_faturalar")
            .upsert({
              firma_id: firmaId,
              kaynak: "api",
              durum: "aktarildi",
              ettn,
              fatura_no: faturaNo,
              fatura_tarihi: parsed.faturaTarihi,
              senaryo: parsed.senaryo,
              cari_unvan: parsed.cariUnvan || "Bilinmeyen Tedarikçi",
              vergi_no: parsed.vergiNo,
              vergi_dairesi: parsed.vergiDairesi,
              fatura_adres: parsed.faturaAdres,
              para_birimi: normalizeCurrencyCode(parsed.paraBirimi),
              ara_toplam_tutar: parsed.araToplamTutar,
              kdv_tutari: parsed.kdvTutari,
              toplam_tutar: parsed.toplamTutar,
              fatura_id: mevcutFatura.fatura_id,
              red_sebebi: null,
              ham_xml: invoiceXml,
              ham_json: {
                invoice_id: invoiceId,
                vkn,
                kaynak: "uyumsoft_api",
                eslesen_fatura_id: mevcutFatura.fatura_id,
                eslesme_nedeni: mevcutFatura.eslesme_nedeni,
                sync_tarihi: now.toISOString(),
              },
              updated_at: now.toISOString(),
            }, { onConflict: "firma_id,kaynak,ettn" });
          aktarilan++;
          continue;
        }

        const { data: upserted, error: upsertError } = await supabaseAdmin
          .from("uyumsoft_gelen_faturalar")
          .upsert({
            firma_id: firmaId,
            kaynak: "api",
            durum: "beklemede",
            ettn,
            fatura_no: faturaNo,
            fatura_tarihi: parsed.faturaTarihi,
            senaryo: parsed.senaryo,
            cari_unvan: parsed.cariUnvan || "Bilinmeyen Tedarikçi",
            vergi_no: parsed.vergiNo,
            vergi_dairesi: parsed.vergiDairesi,
            fatura_adres: parsed.faturaAdres,
            para_birimi: normalizeCurrencyCode(parsed.paraBirimi),
            ara_toplam_tutar: parsed.araToplamTutar,
            kdv_tutari: parsed.kdvTutari,
            toplam_tutar: parsed.toplamTutar,
            ham_xml: invoiceXml,
            ham_json: {
              invoice_id: invoiceId,
              vkn,
              kaynak: "uyumsoft_api",
              sync_tarihi: now.toISOString(),
            },
            updated_at: now.toISOString(),
          }, { onConflict: "firma_id,kaynak,ettn" })
          .select("id")
          .single();
        if (upsertError) throw upsertError;

        const gelenFaturaId = upserted.id as string;
        await supabaseAdmin
          .from("uyumsoft_gelen_fatura_kalemleri")
          .delete()
          .eq("firma_id", firmaId)
          .eq("gelen_fatura_id", gelenFaturaId);

        if (parsed.kalemler.length > 0) {
          const { error: kalemError } = await supabaseAdmin
            .from("uyumsoft_gelen_fatura_kalemleri")
            .insert(parsed.kalemler.map((kalem) => ({
              ...kalem,
              firma_id: firmaId,
              gelen_fatura_id: gelenFaturaId,
            })));
          if (kalemError) throw kalemError;
        }

        aktarilan++;
      } catch (err) {
        const hataMesaji = (err as Error).message;
        hatalar.push(`${invoiceId}: ${hataMesaji}`);
        await hataKaydiYaz(
          supabaseAdmin,
          firmaId,
          invoiceId,
          hataMesaji,
          now,
          vkn,
        );
      }
    }

    await supabaseAdmin
      .from("uyumsoft_entegrasyon_ayarlari")
      .upsert({
        firma_id: firmaId,
        aktif: true,
        endpoint: uyumsoftEndpoint,
        kullanici_adi: username,
        son_senkronizasyon_tarihi: now.toISOString(),
        ek_bilgi: {
          vkn,
          son_sorgu: {
            baslangic_tarihi: startDate.toISOString(),
            bitis_tarihi: endDate.toISOString(),
            tarih_tipi: tarihTipi,
            limit,
          },
        },
        updated_at: now.toISOString(),
      }, { onConflict: "firma_id" });

    return json({
      success: true,
      bulunan: invoiceIds.length,
      aktarilan,
      hatalar,
      baslangic_tarihi: startDate.toISOString(),
      bitis_tarihi: endDate.toISOString(),
      tarih_tipi: tarihTipi,
      limit,
    });
  } catch (err) {
    const message = (err as Error).message;
    const yetkiHatasi =
      message.includes("gerekli yetkiniz yok") ||
      message.includes("yetkiniz yok") ||
      message.includes("Unauthorized") ||
      message.includes("Forbidden");
    const kimlikHatasi =
      message.includes("password") ||
      message.includes("Password") ||
      message.includes("kullanici") ||
      message.includes("Kullanici") ||
      message.includes("user") ||
      message.includes("User");

    return json(
      {
        success: false,
        code: yetkiHatasi
          ? "uyumsoft_yetki_yok"
          : kimlikHatasi
            ? "uyumsoft_kimlik_hatasi"
            : "uyumsoft_sync_error",
        error: yetkiHatasi
          ? "Uyumsoft entegrasyon yetkisi yok. Web Servis Kullanicisi yetkisini ve gerekiyorsa Supabase Edge Function IP erisim iznini kontrol edin."
          : kimlikHatasi
            ? "Uyumsoft web servis kullanici adi veya sifresi hatali gorunuyor. Portal kullanicisi degil, Uyumsoft'un verdigi Web Servis Kullanicisi ve sifresi kullanilmalidir."
            : `Uyumsoft senkronizasyon hatasi: ${message}`,
        detail: message,
      },
      yetkiHatasi ? 403 : 500,
    );
  }
});

async function mevcutFaturaBul(
  supabaseAdmin: ReturnType<typeof createClient>,
  firmaId: string,
  faturaNo: string,
  ettn: string,
) {
  const temizFaturaNo = faturaNo.trim();
  if (temizFaturaNo) {
    const { data: faturaNoEslesme } = await supabaseAdmin
      .from("faturalar")
      .select("fatura_id")
      .eq("firma_id", firmaId)
      .eq("fatura_no", temizFaturaNo)
      .neq("durum", "iptal")
      .limit(1)
      .maybeSingle();
    if (faturaNoEslesme) {
      return {
        fatura_id: faturaNoEslesme.fatura_id,
        eslesme_nedeni: "fatura_no",
      };
    }
  }

  const temizEttn = ettn.trim();
  if (temizEttn) {
    const { data: ettnEslesme } = await supabaseAdmin
      .from("faturalar")
      .select("fatura_id")
      .eq("firma_id", firmaId)
      .eq("efatura_uuid", temizEttn)
      .neq("durum", "iptal")
      .limit(1)
      .maybeSingle();
    if (ettnEslesme) {
      return {
        fatura_id: ettnEslesme.fatura_id,
        eslesme_nedeni: "efatura_uuid",
      };
    }
  }

  return null;
}

async function hataKaydiYaz(
  supabaseAdmin: ReturnType<typeof createClient>,
  firmaId: string,
  invoiceId: string,
  hataMesaji: string,
  now: Date,
  vkn: string,
) {
  const { data: mevcut } = await supabaseAdmin
    .from("uyumsoft_gelen_faturalar")
    .select("id,durum")
    .eq("firma_id", firmaId)
    .eq("kaynak", "api")
    .eq("ettn", invoiceId)
    .maybeSingle();

  if (mevcut?.durum && mevcut.durum !== "hata") {
    return;
  }

  await supabaseAdmin
    .from("uyumsoft_gelen_faturalar")
    .upsert({
      firma_id: firmaId,
      kaynak: "api",
      durum: "hata",
      ettn: invoiceId,
      fatura_no: invoiceId,
      fatura_tarihi: now.toISOString(),
      cari_unvan: "Detay indirilemedi",
      para_birimi: "TRY",
      ara_toplam_tutar: 0,
      kdv_tutari: 0,
      toplam_tutar: 0,
      red_sebebi: hataMesaji,
      ham_json: {
        invoice_id: invoiceId,
        vkn,
        kaynak: "uyumsoft_api",
        hata: hataMesaji,
        sync_tarihi: now.toISOString(),
      },
      updated_at: now.toISOString(),
    }, { onConflict: "firma_id,kaynak,ettn" });
}

async function soapCall(
  operation: string,
  bodyInnerXml: string,
  username: string,
  password: string,
) {
  const envelope = `<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
  <soapenv:Header>
    <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <wsse:UsernameToken>
        <wsse:Username>${escapeXml(username)}</wsse:Username>
        <wsse:Password>${escapeXml(password)}</wsse:Password>
      </wsse:UsernameToken>
    </wsse:Security>
  </soapenv:Header>
  <soapenv:Body>
    <tem:${operation}>
      ${bodyInnerXml}
    </tem:${operation}>
  </soapenv:Body>
</soapenv:Envelope>`;

  const response = await fetch(uyumsoftEndpoint, {
    method: "POST",
    headers: {
      "Content-Type": "text/xml; charset=utf-8",
      SOAPAction: `http://tempuri.org/IIntegration/${operation}`,
    },
    body: envelope,
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${text.slice(0, 400)}`);
  }
  return text;
}

function buildGetInboxInvoiceListBody(
  startDate: Date,
  endDate: Date,
  tarihTipi: TarihTipi,
  pageIndex: number,
  pageSize: number,
) {
  const executionStart =
    tarihTipi === "fatura" ? startDate.toISOString() : nilTag("ExecutionStartDate");
  const executionEnd =
    tarihTipi === "fatura" ? endDate.toISOString() : nilTag("ExecutionEndDate");
  const createStart =
    tarihTipi === "olusturma" ? startDate.toISOString() : nilTag("CreateStartDate");
  const createEnd =
    tarihTipi === "olusturma" ? endDate.toISOString() : nilTag("CreateEndDate");

  return `<tem:query PageIndex="${pageIndex}" PageSize="${pageSize}" OnlyNewestInvoices="true">
    ${dateTag("ExecutionStartDate", executionStart)}
    ${dateTag("ExecutionEndDate", executionEnd)}
    ${dateTag("CreateStartDate", createStart)}
    ${dateTag("CreateEndDate", createEnd)}
    <tem:Status i:nil="true" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/>
    <tem:SortColumn i:nil="true" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/>
    <tem:SortMode i:nil="true" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/>
    <tem:IsArchived i:nil="true" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/>
  </tem:query>`;
}

function dateTag(name: string, value: string) {
  return value.startsWith("<")
    ? value
    : `<tem:${name}>${escapeXml(value)}</tem:${name}>`;
}

function nilTag(name: string) {
  return `<tem:${name} i:nil="true" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/>`;
}

function parseDate(value: unknown) {
  if (typeof value !== "string" || !value.trim()) return undefined;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date;
}

function normalizeLimit(value: unknown) {
  const parsed = Number(value ?? 50);
  if (!Number.isFinite(parsed)) return 50;
  return Math.min(Math.max(Math.trunc(parsed), 1), 500);
}

type TarihTipi = "fatura" | "olusturma";
type TarihTipiSecimi = TarihTipi | "tum";

function normalizeTarihTipi(value: unknown): TarihTipiSecimi {
  if (value === "fatura" || value === "olusturma" || value === "tum") {
    return value;
  }
  return "tum";
}

async function getInboxInvoiceIds(
  startDate: Date,
  endDate: Date,
  tarihTipi: TarihTipiSecimi,
  limit: number,
  username: string,
  password: string,
) {
  const tipler: TarihTipi[] =
    tarihTipi === "tum" ? ["fatura", "olusturma"] : [tarihTipi];
  const ids: string[] = [];
  const seen = new Set<string>();

  for (const tip of tipler) {
    let pageIndex = 0;
    let collectedForTip = 0;
    const pageSize = Math.min(limit, 100);
    while (collectedForTip < limit) {
      const countBeforePage = ids.length;
      const listXml = await soapCall(
        "GetInboxInvoiceList",
        buildGetInboxInvoiceListBody(
          startDate,
          endDate,
          tip,
          pageIndex,
          pageSize,
        ),
        username,
        password,
      );
      assertSuccess(listXml, "GetInboxInvoiceList");

      const pageIds = extractInvoiceIds(listXml);
      for (const id of pageIds) {
        const normalized = id.trim();
        if (!normalized || seen.has(normalized)) continue;
        seen.add(normalized);
        ids.push(normalized);
        collectedForTip++;
        if (collectedForTip >= limit) break;
      }

      if (ids.length === countBeforePage) break;
      if (pageIds.length < pageSize) break;
      pageIndex++;
    }
  }

  return ids;
}

function assertSuccess(xml: string, operation: string) {
  const result = firstTagBlock(xml, `${operation}Result`) ?? xml;
  const fault = firstTagValue(xml, "faultstring");
  if (fault) {
    throw new Error(`${operation} başarısız: ${fault}`);
  }

  const successText =
    firstTagValue(result, "IsSucceded") ??
    firstTagValue(result, "IsSucceeded") ??
    firstTagValue(result, "Succeeded") ??
    firstTagValue(result, "Success") ??
    firstTagValue(result, "Status") ??
    firstTagValue(result, "State");
  const isSucceded =
    /IsSucceded=["']true["']/i.test(result) ||
    /IsSucceeded=["']true["']/i.test(result) ||
    successText?.toLocaleLowerCase("tr-TR") === "true" ||
    successText?.toLocaleLowerCase("tr-TR") === "completedsuccessfully" ||
    /\bCompletedSuccessfully\b/i.test(result) ||
    />\s*1300\s*</.test(result) ||
    /\b1300\b/.test(result);

  if (!isSucceded) {
    const message =
      attr(result, "Message") ||
      firstTagValue(result, "Message") ||
      firstTagValue(result, "ErrorMessage") ||
      firstTagValue(result, "Description") ||
      firstTagValue(result, "ResultMessage") ||
      firstTagValue(result, "StatusMessage");
    const preview = result.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim()
      .slice(0, 240);
    throw new Error(
      `${operation} başarısız: ${message || preview || "Bilinmeyen hata"}`,
    );
  }
}

function extractInvoiceIds(xml: string) {
  const guidMatches =
    xml.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi) ??
      [];
  const strongIds = [
    ...extractTagValues(xml, "UUID"),
    ...extractTagValues(xml, "ETTN"),
    ...extractTagValues(xml, "DocumentUUID"),
    ...extractTagValues(xml, "EnvelopeUUID"),
    ...guidMatches,
  ]
    .map((value) => value.trim())
    .filter(Boolean)
    .filter((value, index, arr) => arr.indexOf(value) === index);
  if (strongIds.length > 0) return strongIds;

  return [
    ...extractTagValues(xml, "InvoiceId"),
    ...extractTagValues(xml, "InvoiceID"),
    ...extractTagValues(xml, "DocumentId"),
    ...extractTagValues(xml, "DocumentID"),
  ]
    .map((value) => value.trim())
    .filter(Boolean)
    .filter((value, index, arr) => arr.indexOf(value) === index);
}

function extractInvoiceXml(dataXml: string) {
  const rawData =
    firstTagValue(dataXml, "Data") ??
    firstTagValue(dataXml, "InvoiceData") ??
    firstTagValue(dataXml, "DocumentData") ??
    firstTagValue(dataXml, "Value") ??
    firstTagValue(dataXml, "Content") ??
    firstTagValue(dataXml, "Xml") ??
    firstTagValue(dataXml, "XML") ??
    firstTagValue(dataXml, "UBL") ??
    firstTagValue(dataXml, "Message") ??
    firstTagValue(dataXml, "ResultMessage");

  if (rawData) {
    const trimmed = rawData.trim();
    if (trimmed.startsWith("<")) return trimmed;
    try {
      const decoded = decodeBase64Utf8(trimmed);
      if (decoded.trim().startsWith("<")) return decoded;
    } catch (_) {
      // Data alani base64 degilse asagida tam cevap icinde UBL aranir.
    }
  }

  const invoiceBlock =
    firstTagBlock(dataXml, "Invoice") ??
    firstTagBlock(dataXml, "CreditNote");
  if (invoiceBlock) {
    const tag = firstTagBlock(dataXml, "Invoice") ? "Invoice" : "CreditNote";
    return `<${tag}>${invoiceBlock}</${tag}>`;
  }

  const base64Candidates =
    dataXml.match(/[A-Za-z0-9+/=]{120,}/g) ?? [];
  for (const candidate of base64Candidates) {
    try {
      const decoded = decodeBase64Utf8(candidate);
      if (decoded.trim().startsWith("<")) return decoded;
    } catch (_) {
      // Base64'e benzeyen her parca gercek data olmayabilir.
    }
  }

  return undefined;
}

function parseUblInvoice(xml: string) {
  const supplier = section(xml, "AccountingSupplierParty");
  const monetaryTotal = section(xml, "LegalMonetaryTotal");
  const taxTotal = section(xml, "TaxTotal");
  const araToplam =
    money(text(monetaryTotal, "TaxExclusiveAmount")) ??
    money(text(monetaryTotal, "LineExtensionAmount")) ??
    0;
  const kdv = money(text(taxTotal, "TaxAmount")) ?? 0;
  const toplam =
    money(text(monetaryTotal, "PayableAmount")) ??
    money(text(monetaryTotal, "TaxInclusiveAmount")) ??
    araToplam + kdv;

  return {
    ettn: text(xml, "UUID"),
    faturaNo: text(xml, "ID"),
    faturaTarihi: text(xml, "IssueDate") ?? new Date().toISOString(),
    senaryo: text(xml, "ProfileID") ?? text(xml, "InvoiceTypeCode"),
    cariUnvan: partyTitle(supplier),
    vergiNo: text(supplier, "CompanyID"),
    vergiDairesi: text(section(supplier, "TaxScheme"), "Name"),
    faturaAdres: buildAddress(supplier),
    paraBirimi: normalizeCurrencyCode(
      attr(firstTagBlock(monetaryTotal, "PayableAmount") ?? "", "currencyID") ??
        text(xml, "DocumentCurrencyCode"),
    ),
    araToplamTutar: araToplam,
    kdvTutari: kdv,
    toplamTutar: toplam,
    kalemler: invoiceLines(xml),
  };
}

function partyTitle(partyWrapper: string) {
  const party = section(partyWrapper, "Party") || partyWrapper;
  return firstNonEmpty([
    text(section(party, "PartyLegalEntity"), "RegistrationName"),
    text(section(party, "PartyName"), "Name"),
    text(party, "RegistrationName"),
    text(party, "Name"),
    text(partyWrapper, "RegistrationName"),
    text(partyWrapper, "Name"),
  ]);
}

function firstNonEmpty(values: Array<string | undefined>) {
  for (const value of values) {
    const trimmed = value?.trim();
    if (trimmed) return trimmed;
  }
  return undefined;
}

function normalizeCurrencyCode(value?: string) {
  const code = value?.trim().toUpperCase() || "TRY";
  return ["TL", "TRL", "YTL"].includes(code) ? "TRY" : code;
}

function invoiceLines(xml: string) {
  return blocks(xml, "InvoiceLine").map((line, index) => {
    const item = section(line, "Item");
    const price = section(line, "Price");
    const taxTotal = section(line, "TaxTotal");
    const miktar = money(text(line, "InvoicedQuantity")) ?? 1;
    const lineTotal = money(text(line, "LineExtensionAmount")) ?? 0;
    const kdv = money(text(taxTotal, "TaxAmount")) ?? 0;
    const birimFiyat = money(text(price, "PriceAmount")) ??
      (miktar === 0 ? lineTotal : lineTotal / miktar);
    const urunAdi = text(item, "Name") ?? `Fatura kalemi ${index + 1}`;
    const aciklama = text(line, "Note");
    return {
      sira_no: index + 1,
      kategori: guessCategory(`${urunAdi} ${aciklama ?? ""}`),
      urun_kodu: text(section(item, "SellersItemIdentification"), "ID"),
      urun_adi: urunAdi,
      aciklama,
      miktar,
      birim: attr(firstTagBlock(line, "InvoicedQuantity") ?? "", "unitCode") ?? "adet",
      birim_fiyat: birimFiyat,
      iskonto_orani: 0,
      iskonto_tutari: 0,
      kdv_orani: money(text(line, "Percent")) ?? 20,
      kdv_tutari: kdv,
      toplam_tutar: lineTotal + kdv,
    };
  });
}

function guessCategory(value: string) {
  const lower = value.toLocaleLowerCase("tr-TR");
  if (lower.includes("iplik")) return "iplik";
  if (lower.includes("aksesuar") || lower.includes("düğme") || lower.includes("dugme") || lower.includes("fermuar")) {
    return "aksesuar";
  }
  if (lower.includes("fason") || lower.includes("dikim") || lower.includes("yıkama") || lower.includes("nakış") || lower.includes("ütü")) {
    return "fason_uretim";
  }
  if (lower.includes("nakliye") || lower.includes("kargo")) return "nakliye";
  if (lower.includes("personel") || lower.includes("maaş") || lower.includes("maas")) return "personel";
  if (lower.includes("kira") || lower.includes("elektrik") || lower.includes("doğalgaz") || lower.includes("dogalgaz")) {
    return "genel_gider";
  }
  return "diger";
}

function decodeBase64Utf8(value: string) {
  const binary = atob(value.replace(/\s/g, ""));
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return new TextDecoder("utf-8").decode(bytes);
}

function text(xml: string, tag: string) {
  const block = firstTagBlock(xml, tag);
  if (!block) return undefined;
  return decodeXml(block.replace(/<[^>]+>/g, "").trim()) || undefined;
}

function firstTagValue(xml: string, tag: string) {
  return text(xml, tag);
}

function firstTagBlock(xml: string, tag: string) {
  return blocks(xml, tag)[0];
}

function section(xml: string, tag: string) {
  return firstTagBlock(xml, tag) ?? "";
}

function blocks(xml: string, tag: string) {
  const regex = new RegExp(`<(?:[A-Za-z0-9_]+:)?${tag}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:[A-Za-z0-9_]+:)?${tag}>`, "gi");
  return [...xml.matchAll(regex)].map((match) => match[1] ?? "");
}

function extractTagValues(xml: string, tag: string) {
  return blocks(xml, tag)
    .map((block) => decodeXml(block.replace(/<[^>]+>/g, "").trim()))
    .filter(Boolean) as string[];
}

function attr(xml: string, attrName: string) {
  const match = new RegExp(`${attrName}=["']([^"']+)["']`, "i").exec(xml);
  return decodeXml(match?.[1]);
}

function money(value?: string) {
  if (!value) return undefined;
  const raw = value.replace(/[^0-9,.\-]/g, "");
  if (!raw) return undefined;
  const lastComma = raw.lastIndexOf(",");
  const lastDot = raw.lastIndexOf(".");
  let normalized = raw;
  if (lastComma >= 0 && lastDot >= 0) {
    const decimal = lastComma > lastDot ? "," : ".";
    const thousands = decimal === "," ? "." : ",";
    normalized = raw.replaceAll(thousands, "").replace(decimal, ".");
  } else if (lastComma >= 0) {
    normalized = raw.replaceAll(".", "").replace(",", ".");
  }
  return Number(normalized);
}

function buildAddress(supplier: string) {
  return [
    text(supplier, "StreetName"),
    text(supplier, "BuildingName"),
    text(supplier, "BuildingNumber"),
    text(supplier, "CitySubdivisionName"),
    text(supplier, "CityName"),
    text(supplier, "PostalZone"),
  ].filter(Boolean).join(" ");
}

function escapeXml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function decodeXml(value?: string) {
  if (!value) return value;
  return value
    .replaceAll("&amp;", "&")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", '"')
    .replaceAll("&apos;", "'");
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
