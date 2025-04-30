// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// import { corsHeaders } from '../_shared/cors.ts' // Kaldırıldı, yerine temel başlıklar eklendi

// Temel CORS başlıkları
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// OpenAI API Endpoint
const OPENAI_API_ENDPOINT = 'https://api.openai.com/v1/chat/completions';
// Kullanılacak OpenAI modeli (Güncellendi)
const OPENAI_MODEL = 'gpt-4.1-2025-04-14';

console.log(`Function generate-text-from-ai started (using OpenAI: ${OPENAI_MODEL}).`);

serve(async (req) => {
  // CORS preflight isteğini işle
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Request Validation (CORS başlıkları güncellendi)
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    let documentType: string | undefined;
    let data: Record<string, string> | undefined;
    try {
      const body = await req.json();
      documentType = body.documentType;
      data = body.data as Record<string, string>;
    } catch (e) {
      console.error("Failed to parse request body:", e);
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    if (!documentType || typeof documentType !== 'string' || documentType.trim() === '') {
       return new Response(JSON.stringify({ error: "Missing or invalid 'documentType' field" }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }
    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
       return new Response(JSON.stringify({ error: "Missing or invalid 'data' field (must be a non-empty object)" }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }
    console.log(`Received request for document type: ${documentType}`);

    // 2. Get API Key from Environment Variables (İsim OPENAI_API_KEY olarak güncellendi)
    const apiKey = Deno.env.get('OPENAI_API_KEY');
    if (!apiKey) {
      console.error("Environment variable OPENAI_API_KEY is not set."); // Hata mesajı güncellendi
      throw new Error('Server configuration error: Missing OpenAI API Key.');
    }
    console.log("OpenAI API Key loaded.");

    // 3. Construct Prompt (İyileştirildi)
    const dataString = Object.entries(data).map(([key, value]) => `- ${key}: ${value}`).join('\n');

    const systemPrompt = `Sen Türkiye'deki hukuki süreçler konusunda uzmanlaşmış bir yapay zeka asistanısın. Görevin, sana verilen bilgilerle belirli bir tür hukuki belge metnini hazırlamaktır. Çıktın SADECE belgenin kendisi olmalı, herhangi bir ek açıklama, selamlama, başlık veya sonuç paragrafı içermelidir. Metin, doğrudan bir PDF dosyasına yazdırılabilecek nihai formatta olmalıdır. Kullanılan dil resmi ve hukuki terminolojiye uygun olmalıdır. Türkçe karakterleri doğru kullanmaya özen göster.`;

    const userPrompt = `Aşağıdaki detayları kullanarak bir '${documentType}' oluşturmanı istiyorum:

### Sağlanan Bilgiler:
${dataString}

### Talimatlar:
1. Yukarıdaki bilgileri kullanarak istenen '${documentType}' belgesinin tam metnini oluştur.
2. Kesinlikle belge metni dışında HİÇBİR ŞEY yazma (Açıklama, not, başlık, selamlama, kapanış cümlesi vb. YASAK).
3. Çıktı doğrudan PDF olarak kullanılacaktır, bu yüzden sadece belge içeriğini üret.
4. Resmi ve hukuki bir dil kullan.
`;

    console.log("Constructed User Prompt (first 100 chars):", userPrompt.substring(0, 100) + "...");

    // 4. Call OpenAI API (Model adı güncellendi)
    console.log("Calling OpenAI API...");
    let generatedText = '';

    try {
      const openaiResponse = await fetch(OPENAI_API_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: OPENAI_MODEL, // Model güncellendi
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: userPrompt },
          ],
          temperature: 0.3, // Daha tutarlı çıktılar için sıcaklığı biraz düşürelim
          // max_tokens: 2048, // Gerekirse token limitini artırabilirsiniz
        }),
      });

      if (!openaiResponse.ok) {
        const errorBody = await openaiResponse.json();
        console.error(`OpenAI API Error: ${openaiResponse.status} - ${JSON.stringify(errorBody)}`);
        throw new Error(`OpenAI API failed with status ${openaiResponse.status}: ${errorBody?.error?.message ?? 'Unknown error'}`);
      }
      const responseBody = await openaiResponse.json();
      generatedText = responseBody?.choices?.[0]?.message?.content?.trim() ?? '';
      if (!generatedText) {
         console.warn("OpenAI API response structure might have changed or text is missing.");
         console.log("Full OpenAI Response:", JSON.stringify(responseBody, null, 2));
         const finishReason = responseBody?.choices?.[0]?.finish_reason;
         if (finishReason && finishReason !== 'stop') {
            throw new Error(`AI content generation stopped unexpectedly. Reason: ${finishReason}`);
         }
         throw new Error("AI could not generate text or response format is unexpected.");
      }
      console.log("OpenAI API call successful. Text generated.");

    } catch (e) {
       console.error("Error during OpenAI API call:", e);
       throw new Error(`Failed to call AI text generation API: ${e.message}`);
    }

    // 5. Return Generated Text (CORS başlıkları güncellendi)
    return new Response(
      JSON.stringify({ generatedText: generatedText }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error("!!! Unhandled Error in generate-text-from-ai function:", error);
    return new Response(
      JSON.stringify({ error: error.message || 'An unexpected error occurred.' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

console.log("generate-text-from-ai function handler registered (OpenAI).");

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/generate-text-from-ai' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
