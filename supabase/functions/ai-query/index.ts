/// <reference types="https://esm.sh/v135/@supabase/functions-js@2.3.1/src/edge-runtime.d.ts" />

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts' // Paylaşılan CORS başlıkları için

// OpenAI API endpoint'i (sabit)
const OPENAI_API_ENDPOINT = 'https://api.openai.com/v1/chat/completions';
const API_KEY_SECRET_NAME = 'OPENAI_API_KEY'; // Supabase Secrets'daki anahtar adınız

serve(async (req: Request) => {
  // CORS preflight isteğini işle
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // İstek gövdesinden soruyu al
    const requestData = await req.json();
    const { question } = requestData;
    
    if (!question || typeof question !== 'string') {
      throw new Error('Missing or invalid "question" parameter in the request body.');
    }

    // Supabase Secrets'tan API anahtarını al
    const apiKey = Deno.env.get(API_KEY_SECRET_NAME);
    if (!apiKey) {
      throw new Error(`API Key secret "${API_KEY_SECRET_NAME}" not found in Supabase secrets. Please make sure to set it in your Supabase project.`);
    }

    console.log('Sending request to OpenAI API...');

    // OpenAI API'sine istek gönder
    const response = await fetch(OPENAI_API_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4.1-mini-2025-04-14',
        messages: [
          {
            role: 'system',
            content: 'Sen Türkiye hukuku hakkında genel soruları yanıtlayan bir yapay zeka asistanısın. Kesinlikle yasal tavsiye vermemelisin. Yalnızca bilgilendirme amaçlı yanıtlar üretmelisin. Eğer bir sorunun cevabını bilmiyorsan veya soru yasal tavsiye niteliğindeyse, bunu açıkça belirtmeli ve bir avukata danışılmasını önermelisin.'
          },
          {
            role: 'user',
            content: question
          }
        ],
        max_tokens: 800,
        temperature: 0.7,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenAI API Error:', response.status, errorText);
      
      let errorMessage = `OpenAI API yanıt hatası: ${response.status}`;
      
      try {
        // JSON hata yanıtını parse et (eğer varsa)
        const errorJson = JSON.parse(errorText);
        if (errorJson.error && errorJson.error.message) {
          errorMessage = `OpenAI API hatası: ${errorJson.error.message}`;
        }
      } catch (parseError) {
        // JSON parse hatası - ham hata metnini kullan
      }
      
      throw new Error(errorMessage);
    }

    const responseData = await response.json();
    console.log('OpenAI API response received successfully');

    // ChatCompletion API yanıtından cevabı çıkar
    const answer = responseData.choices[0].message.content;

    // Başarılı yanıtı döndür
    return new Response(
      JSON.stringify({ answer: answer }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('Error in ai-query function:', error);
    // Hata yanıtını döndür
    return new Response(
      JSON.stringify({ 
        error: error.message,
        details: "Supabase Edge Function'da bir hata oluştu. Daha fazla bilgi için sunucu günlüklerine bakın."
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
}) 