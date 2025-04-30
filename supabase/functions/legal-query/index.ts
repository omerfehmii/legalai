// @deno-types="https://esm.sh/v135/@supabase/functions-js@2.3.1/src/edge-runtime.d.ts"
// Follow this pattern to import other npm modules
// https://deno.land/manual@v1.41.0/basics/modules/npm_specifiers

import OpenAI from 'https://esm.sh/openai@4.12.4'
import { corsHeaders } from '../_shared/cors.ts'

// Define the expected structure for history messages
interface HistoryMessage {
  role: 'user' | 'assistant';
  content: string;
}

Deno.serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Expect 'history' instead of 'query'
    const { history } = await req.json()
    
    // Validate history input
    if (!Array.isArray(history) || history.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Geçersiz veya boş mesaj geçmişi gönderildi' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // Validate structure of history messages (optional but recommended)
    for (const msg of history) {
      if (!msg || typeof msg.role !== 'string' || typeof msg.content !== 'string' || (msg.role !== 'user' && msg.role !== 'assistant')) {
        return new Response(
          JSON.stringify({ error: 'Geçersiz mesaj formatı gönderildi' }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400 
          }
        )
      }
    }

    // OpenAI client initialization
    const openAiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openAiKey) {
      throw new Error('OPENAI_API_KEY bulunamadı')
    }

    const openai = new OpenAI({
      apiKey: openAiKey
    })

    // Construct messages for OpenAI: System Prompt + Received History
    const messagesForApi = [
      {
        role: 'system',
        // Updated System Prompt: Use Markdown for Documents
        content: `Sen Türkiye hukuku konusunda uzmanlaşmış, hem soruları yanıtlayabilen hem de kullanıcıyla etkileşimli olarak hukuki belgeler oluşturabilen bir yapay zeka asistanısın.\n\nGörevlerin:\n1.  **Soruları Yanıtlamak:** Sorulan hukuki sorulara, konuşma geçmişini dikkate alarak, Türk hukuku çerçevesinde ve ilgili kanun maddelerine atıf yaparak net ve anlaşılır yanıtlar ver.\n2.  **Belge Oluşturma (İki Aşamalı: Önce Taslak, Sonra Doldurma Teklifi):**\n    a.  Kullanıcı bir belge (dilekçe, sözleşme, ihtarname vb.) oluşturmanı istediğinde:\n        i.  **Önce Taslak Metni Ver:** İstenen belge türü için, içinde doldurulması gereken yerlerin köşeli parantez \`[]\` içinde açıkça belirtildiği (örn: \`[Kiracı Adı]\`, \`[Tarih]\`, \`[Adres]\`) genel bir **taslak metin** oluştur. Yanıtına \"İstediğiniz [Belge Türü] için genel bir taslak metin aşağıdadır:\" gibi bir giriş cümlesiyle başla ve ardından taslak metnin tamamını **\`\`\`legal-document** kod bloğu içine alarak ver. Örnek:\n\`\`\`legal-document\n[TASLAK METNİ BURAYA]\n\`\`\`\n        ii. **Doldurmayı Teklif Et:** Taslak metni içeren kod bloğunu verdikten *hemen sonra*, aynı yanıtın devamında, kullanıcıya bu taslağı birlikte doldurmak isteyip istemediğini sor. Örneğin: \"Bu taslağı sizin için doldurmamı isterseniz, gerekli bilgileri (köşeli parantez içindeki alanları) sizden alabilirim. Devam edelim mi?\"\n    b.  Kullanıcı doldurmayı kabul ederse:\n        i.  **Gerekli Bilgileri İste:** Taslaktaki \`[]\` içindeki alanlar için gerekli bilgileri kullanıcıdan açık ve anlaşılır bir şekilde iste.\n        ii. **Bilgileri Topla:** Kullanıcının verdiği bilgileri al.\n        iii. **Doldurulmuş Belgeyi Ver:** Tüm bilgiler toplandıktan sonra, taslağı bu bilgilerle doldurarak nihai belge metnini oluştur. Yanıtına \"İşte bilgilerinizle doldurulmuş [Belge Türü] metni:\" gibi bir giriş yap ve ardından doldurulmuş metnin tamamını yine **\`\`\`legal-document** kod bloğu içine alarak ver.\n    c.  Kullanıcı doldurmayı kabul etmezse veya başka bir konuya geçerse, normal sohbete devam et.\n    d.  **Genel Davranış:** Her zaman resmi, hukuki terminolojiye uygun ve net bir dil kullan. Türkçe karakterleri doğru kullan. Kod blokları dışındaki metinlerde Markdown kullanmaktan kaçın.\n\nÖzetle: Belge metinlerini (hem taslak hem doldurulmuş) her zaman \`\`\`legal-document ... \`\`\` bloğu içine yaz. Taslaktan sonra doldurmayı teklif et.`
      },
      // Spread the validated history array
      ...(history as HistoryMessage[])
    ];

    // Create completion with OpenAI
    const chatCompletion = await openai.chat.completions.create({
      // Consider using a model optimized for chat like gpt-3.5-turbo or gpt-4-turbo if available
      model: 'gpt-4o-mini', // Use the latest available model
      messages: messagesForApi,
    })

    const aiAnswer = chatCompletion.choices[0]?.message?.content ?? "AI'dan yanıt alınamadı";

    // Return the response
    return new Response(
      JSON.stringify({ 
        answer: aiAnswer // Use the extracted variable
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('Error in legal-query function:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Bilinmeyen bir sunucu hatası oluştu' }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})