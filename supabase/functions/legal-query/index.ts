// @deno-types="https://esm.sh/v135/@supabase/functions-js@2.3.1/src/edge-runtime.d.ts"
// Follow this pattern to import other npm modules
// https://deno.land/manual@v1.41.0/basics/modules/npm_specifiers

import OpenAI from 'https://esm.sh/openai@4.12.4'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { query } = await req.json()
    
    if (!query) {
      return new Response(
        JSON.stringify({ error: 'Hukuki soru gönderilmedi' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // OpenAI client initialization
    const openAiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openAiKey) {
      throw new Error('OPENAI_API_KEY bulunamadı')
    }

    const openai = new OpenAI({
      apiKey: openAiKey
    })

    // Create completion with OpenAI
    const chatCompletion = await openai.chat.completions.create({
      model: 'gpt-4.1-mini-2025-04-14',
      messages: [
        {
          role: 'system',
          content: 'Sen Türkiye hukuku konusunda uzmanlaşmış bir hukuk asistanısın. Sorulan hukuki sorulara Türk hukuku çerçevesinde yanıt ver. Yanıtlarında ilgili kanun maddelerine atıf yap ve açıklamalarını destekle.'
        },
        {
          role: 'user',
          content: query
        }
      ],
    })

    // Return the response
    return new Response(
      JSON.stringify({ 
        answer: chatCompletion.choices[0].message.content 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})