// @deno-types="https://esm.sh/v135/@supabase/functions-js@2.3.1/src/edge-runtime.d.ts"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import OpenAI from 'https://esm.sh/openai@4.12.4'; // Use OpenAI library
import { PDFDocument, StandardFonts, rgb } from 'https://esm.sh/pdf-lib@1.17.1';
// Remove base64 import
// import { decode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

// --- Configuration ---
const PDF_STORAGE_BUCKET = 'documents'; // Supabase Storage bucket adı
const OPENAI_MODEL = 'gpt-4o-mini'; // Kullanılacak güncel OpenAI modeli
// Remove FONT_BASE64 constant
// const FONT_BASE64 = "PASTE_YOUR_BASE64_ENCODED_FONT_STRING_HERE";
// --- End Configuration ---

// Temel CORS başlıkları
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

console.log(`Function generate-document started. Model: ${OPENAI_MODEL}, Bucket: ${PDF_STORAGE_BUCKET}`);

// Remove scriptDir calculation

serve(async (req) => {
  // CORS preflight isteğini işle
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Remove font decoding logic
  /*
  let fontBytes: Uint8Array;
  try {
      if (FONT_BASE64 === "PASTE_YOUR_BASE64_ENCODED_FONT_STRING_HERE" || FONT_BASE64.length < 100) {
          throw new Error("FONT_BASE64 constant does not contain the actual base64 string.");
      }
      fontBytes = decode(FONT_BASE64);
      console.log(`Font decoded successfully from base64 string (${fontBytes.length} bytes).`);
  } catch (fontError) {
      console.error(`!!! Failed to decode font from FONT_BASE64 constant:`, fontError);
      return new Response(JSON.stringify({ error: `Server configuration error: Could not decode font data. Details: ${fontError.message}` }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
  }
  */

  try {
    // 1. Request Validation
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    let documentType: string | undefined;
    let data: Record<string, unknown> | undefined; // Allow any value type initially
    try {
      const body = await req.json();
      documentType = body.documentType;
      data = body.data as Record<string, unknown>; // Cast, validation below
    } catch (e) {
      console.error("Failed to parse request body:", e);
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!documentType || typeof documentType !== 'string' || documentType.trim() === '') {
      return new Response(JSON.stringify({ error: "Missing or invalid 'documentType' field" }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
      return new Response(JSON.stringify({ error: "Missing or invalid 'data' field (must be a non-empty object)" }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    const stringData: Record<string, string> = {};
     for (const key in data) {
       if (Object.prototype.hasOwnProperty.call(data, key)) {
         stringData[key] = String(data[key]);
       }
     }
    console.log(`Received request for document type: ${documentType}`);

    // 2. Initialize OpenAI Client
    const openAiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openAiKey) {
      console.error("Environment variable OPENAI_API_KEY is not set.");
      throw new Error('Server configuration error: Missing OpenAI API Key.');
    }
    const openai = new OpenAI({ apiKey: openAiKey });
    console.log("OpenAI client initialized.");

    // 3. Construct Prompt for AI Text Generation
    const dataString = Object.entries(stringData).map(([key, value]) => `- ${key}: ${value}`).join('\n');
    const systemPrompt = `Sen Türkiye'deki hukuki süreçler konusunda uzmanlaşmış bir yapay zeka asistanısın. Görevin, sana verilen bilgilerle belirli bir tür hukuki belge metnini sıfırdan hazırlamaktır. Çıktın SADECE belgenin kendisi olmalı, herhangi bir ek açıklama, selamlama, başlık veya sonuç paragrafı İÇERMEMELİDİR. Metin, doğrudan bir PDF dosyasına yazdırılabilecek nihai formatta olmalıdır. Kullanılan dil resmi ve hukuki terminolojiye uygun olmalıdır. Türkçe karakterleri doğru kullanmaya özen göster. İstenen belge türüne uygun tüm gerekli maddeleri ve standart bölümleri dahil et.`;
    const userPrompt = `Aşağıdaki detayları kullanarak bir '${documentType}' oluşturmanı istiyorum:\n\n### Sağlanan Bilgiler:\n${dataString}\n\n### Talimatlar:\n1. Yukarıdaki bilgileri kullanarak istenen '${documentType}' belgesinin tam ve eksiksiz metnini oluştur.\n2. Kesinlikle belge metni dışında HİÇBİR ŞEY yazma (Açıklama, not, başlık, selamlama, kapanış cümlesi vb. YASAK).\n3. Çıktı doğrudan PDF olarak kullanılacaktır, bu yüzden sadece belge içeriğini üret.\n4. Resmi ve hukuki bir dil kullan.\n5. Belge türüne uygun tüm standart maddeleri (taraflar, konu, tarihler, imzalar için yerler vb.) eklediğinden emin ol.`;
    console.log("Constructed User Prompt (first 100 chars):", userPrompt.substring(0, 100) + "...");

    // 4. Call OpenAI API for Text Generation
    console.log("Calling OpenAI API...");
    let generatedText = '';
    try {
      const chatCompletion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.3,
      });
      generatedText = chatCompletion.choices[0]?.message?.content?.trim() ?? '';
      if (!generatedText) {
        const finishReason = chatCompletion.choices[0]?.finish_reason;
        console.warn("OpenAI response text missing. Finish reason:", finishReason);
        throw new Error(`AI could not generate text. Finish Reason: ${finishReason ?? 'unknown'}`);
      }
      console.log(`AI text generated successfully (${generatedText.length} chars).`);
    } catch (e) {
      console.error("Error during OpenAI API call:", e);
      throw new Error(`Failed to call AI text generation API: ${e.message}`);
    }

    // --- Add Character Replacement --- 
    function replaceTurkishChars(text: string): string {
        const map: { [key: string]: string } = {
            'İ': 'I', 'ı': 'i',
            'Ş': 'S', 'ş': 's',
            'Ğ': 'G', 'ğ': 'g',
            'Ç': 'C', 'ç': 'c',
            'Ö': 'O', 'ö': 'o',
            'Ü': 'U', 'ü': 'u'
        };
        return text.replace(/[İıŞşĞğÇçÖöÜü]/g, (match) => map[match] || match);
    }
    const pdfFriendlyText = replaceTurkishChars(generatedText);
    if (pdfFriendlyText !== generatedText) {
        console.warn('Turkish characters replaced for PDF compatibility.');
    }
    // --- End Character Replacement ---

    // 5. Initialize Supabase Client (Service Role) for Storage
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !serviceRoleKey) {
      console.error("Missing Supabase URL or Service Role Key env vars.");
      throw new Error('Server configuration error: Missing Supabase credentials.');
    }
    const supabaseClient = createClient(supabaseUrl, serviceRoleKey);
    console.log("Supabase service client initialized.");

    // 6. Generate PDF Document using pdf-lib with Standard Font
    console.log("Generating PDF with standard font...");
    const pdfDoc = await PDFDocument.create();
    // Revert back to using a standard font
    // const customFont = await pdfDoc.embedFont(fontBytes);
    let page = pdfDoc.addPage();
    const { width, height } = page.getSize();
    // Use Helvetica again
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica); 
    const fontSize = 11;
    const margin = 50;
    const textWidth = width - 2 * margin;
    const lineHeight = font.heightAtSize(fontSize) * 1.3; 
     const lines: string[] = [];
     const paragraphs = pdfFriendlyText.split('\n');
     for (const paragraph of paragraphs) {
         if (paragraph.trim() === '') { lines.push(''); continue; }
         let currentLine = '';
         const words = paragraph.split(/(\s+)/).filter(w => w.length > 0);
         for (const word of words) {
             const testLine = currentLine + word;
             const currentWidth = font.widthOfTextAtSize(testLine, fontSize);
             if (currentWidth < textWidth) { currentLine = testLine; }
             else {
                 if (currentLine.trim().length > 0) { lines.push(currentLine.trimEnd()); }
                 if (font.widthOfTextAtSize(word.trim(), fontSize) > textWidth) {
                     let partialWord = '';
                     for (const char of word.trim()) {
                         if (font.widthOfTextAtSize(partialWord + char, fontSize) < textWidth) { partialWord += char; }
                         else { lines.push(partialWord); partialWord = char; }
                     }
                     currentLine = partialWord;
                 } else { currentLine = word.trimStart(); }
             }
         }
         if (currentLine.trim().length > 0) { lines.push(currentLine.trimEnd()); }
     }
    let y = height - margin;
    for (const line of lines) {
       if (line.trim().length === 0) { y -= lineHeight; continue; }
       if (y < margin + lineHeight) {
          page = pdfDoc.addPage();
          y = page.getSize().height - margin;
       }
       // Use the standard font here
       page.drawText(line, { x: margin, y, size: fontSize, font: font, color: rgb(0, 0, 0) }); 
       y -= lineHeight;
    }
    const pdfBytes = await pdfDoc.save();
    console.log(`PDF generated successfully (${pdfBytes.length} bytes).`);

    // 7. Upload PDF to Supabase Storage
    const safeDocType = documentType.replace(/[^a-zA-Z0-9-_]/g, '_');
    const filePath = `generated-documents/${safeDocType}_${Date.now()}.pdf`;
    console.log(`Uploading PDF to Storage at path: ${filePath}`);
    const { data: uploadData, error: uploadError } = await supabaseClient.storage
      .from(PDF_STORAGE_BUCKET)
      .upload(filePath, pdfBytes, {
        contentType: 'application/pdf',
        cacheControl: '3600',
        upsert: false,
      });
    if (uploadError) {
      console.error('Storage Upload Error:', uploadError);
      throw new Error(`Failed to upload PDF to storage: ${uploadError.message}`);
    }
    console.log('Storage upload successful:', uploadData);

    // 8. Get Public URL (Optional)
    let publicUrl: string | null = null;
    try {
      const { data: urlData } = supabaseClient.storage
        .from(PDF_STORAGE_BUCKET)
        .getPublicUrl(filePath);
      publicUrl = urlData?.publicUrl;
      console.log("Public URL obtained:", publicUrl);
    } catch (urlError) {
      console.warn("Could not get public URL:", urlError.message);
    }

    // 9. Return Success Response
    return new Response(
      JSON.stringify({
        message: "Document generated and uploaded successfully.",
        filePath: uploadData?.path,
        publicUrl: publicUrl,
        bucket: PDF_STORAGE_BUCKET,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error("!!! Unhandled Error in generate-document function:", error);
    return new Response(
      JSON.stringify({ error: error.message || 'An unexpected server error occurred.' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
}); 