// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

// @deno-types="https://esm.sh/v135/@supabase/functions-js@2.3.1/src/edge-runtime.d.ts"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { PDFDocument, StandardFonts, rgb } from 'https://esm.sh/pdf-lib@1.17.1';
// Import Deno base64 encode function
import { encode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

// --- Configuration --- (Remove Storage Bucket)
// const PDF_STORAGE_BUCKET = 'documents';
// --- End Configuration ---

console.log(`Function generate-pdf started (returns base64).`);

// CORS Headers (Keep)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  try {
    // 1. Validate Request: Check method and get content
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
          status: 405,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    let documentContent: string | undefined;
    try {
      const body = await req.json();
      documentContent = body.documentContent;
    } catch (e) {
      console.error("Failed to parse request body:", e);
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!documentContent || typeof documentContent !== 'string' || documentContent.trim() === '') {
      console.error("Validation Error: Missing or empty 'documentContent'");
      return new Response(JSON.stringify({ error: "Missing or invalid 'documentContent' field" }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    console.log("Received document content successfully.");

    // Remove Supabase Client Initialization

    // --- Add Character Replacement ---
    function replaceTurkishChars(text: string): string {
        const map: { [key: string]: string } = {
            'İ': 'I', 'ı': 'i', 'Ş': 'S', 'ş': 's', 'Ğ': 'G', 'ğ': 'g',
            'Ç': 'C', 'ç': 'c', 'Ö': 'O', 'ö': 'o', 'Ü': 'U', 'ü': 'u'
        };
        return text.replace(/[İıŞşĞğÇçÖöÜü]/g, (match) => map[match] || match);
    }
    const pdfFriendlyText = replaceTurkishChars(documentContent || '');
    if (pdfFriendlyText !== (documentContent || '')) {
        console.warn('Turkish characters replaced for PDF compatibility.');
    }
    // --- End Character Replacement ---

    // 3. Generate PDF Document using pdf-lib
    console.log("Generating PDF bytes...");
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage();
    const { width, height } = page.getSize();
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

    // Draw the wrapped lines onto the PDF page(s)
    let y = height - margin;
    for (const line of lines) {
      if (line.trim().length === 0) { y -= lineHeight; continue; }
      if (y < margin + lineHeight) {
         const newPage = pdfDoc.addPage(); // Use newPage reference if needed
         y = newPage.getSize().height - margin;
         newPage.drawText(line, { x: margin, y, size: fontSize, font, color: rgb(0, 0, 0) });
      } else {
         page.drawText(line, { x: margin, y, size: fontSize, font, color: rgb(0, 0, 0) });
      }
      y -= lineHeight;
    }

    const pdfBytes = await pdfDoc.save(); // Get PDF as Uint8Array
    console.log(`PDF generated successfully (${pdfBytes.length} bytes).`);

    // 4. Convert PDF bytes to Base64
    const pdfBase64 = encode(pdfBytes);
    console.log("PDF bytes encoded to base64.");

    // Remove Storage Upload and Get Public URL logic

    // 5. Return Success Response with Base64 PDF
    return new Response(
      JSON.stringify({ pdfBase64: pdfBase64 }), // Return only base64 string
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error("!!! Unhandled Error in generate-pdf function:", error);
    if (error instanceof Error && error.stack) {
      console.error(error.stack);
    }
    return new Response(
      JSON.stringify({ error: error.message || 'An unexpected error occurred.' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

// Remove old log message
// console.log("generate-pdf function handler registered.");

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/generate-pdf' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/

// PDF'i Supabase Storage'a yükle
console.log(`Uploading file to Storage...`);
