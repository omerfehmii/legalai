// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

console.log("Hello from Functions!")

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

// --- LLM ve Yardımcı Fonksiyonlar ---
const OPENAI_API_ENDPOINT = 'https://api.openai.com/v1/chat/completions';
const API_KEY_SECRET_NAME = 'OPENAI_API_KEY'; // Supabase Secret adı (Güncellendi)

async function callOpenAI(messages, apiKey, temperature = 0.7, max_tokens = 800, expectJson = false) {
  console.log('Sending request to OpenAI API...');
  const body = {
    model: 'gpt-4.1-mini-2025-04-14', // Model güncellendi
    messages: messages,
    max_tokens: max_tokens,
    temperature: temperature
  };
  // JSON format isteme kısmı aynı kalabilir, model adı kontrolü güncellendi
  if (expectJson && (body.model.startsWith('gpt-4') || body.model.includes('gpt-3.5-turbo-1106'))) {
    body.response_format = {
      type: "json_object"
    };
    console.log('Requesting JSON response format.');
  }
  // ... (fetch ve hata kontrolü aynı)
  const response = await fetch(OPENAI_API_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify(body)
  });
  if (!response.ok) {
    const errorText = await response.text();
    console.error('OpenAI API Error:', response.status, errorText);
    let errorMessage = `OpenAI API yanıt hatası: ${response.status}`;
    try {
      const errorJson = JSON.parse(errorText);
      if (errorJson.error && errorJson.error.message) errorMessage = `OpenAI API hatası: ${errorJson.error.message}`;
    } catch (parseError) {}
    throw new Error(errorMessage);
  }
  const responseData = await response.json();
  console.log('OpenAI API response received successfully');
  let content = responseData.choices[0].message.content;
  if (expectJson) {
    try {
      const parsedJson = JSON.parse(content);
      console.log('Parsed JSON response:', parsedJson);
      return parsedJson;
    } catch (e) {
      console.error("Failed to parse expected JSON response:", content, e);
      return {
        intent: 'unknown',
        error: "LLM'den beklenen JSON formatı alınamadı."
      };
    }
  }
  console.log('Plain text response:', content);
  return content;
}

// getTemplateDetails fonksiyonu templateId'yi DB'de aradığı için adı aynı kalabilir
// Ancak çağıran yerin doğru parametreyi (documentType) vermesi lazım
async function getTemplateDetails(documentId, supabaseClient) {
  console.log("Fetching template details from DB for:", documentId);
  try {
    const { data, error } = await supabaseClient.from('document_templates')
    .select('name, fields')
    .eq('id', documentId)
    .single();
    if (error) {
      if (error.code === 'PGRST116') {
        console.warn(`Template/Document with id ${documentId} not found.`);
        return null;
      }
      throw new Error(`Database error fetching template: ${error.message}`);
    }
    if (!data || !data.fields || !Array.isArray(data.fields)) {
      console.error('Invalid template data structure received:', data);
      return null;
    }
    return {
      name: data.name,
      fields: data.fields
    };
  } catch (dbError) {
    console.error(`Exception during getTemplateDetails for ${documentId}:`, dbError);
    return null;
  }
}

// --- Ana Fonksiyon ---
serve(async (req)=>{
  // ... (CORS preflight aynı) ...
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const requestData = await req.json();
    console.log("Received Request:", requestData);

    // Parametre adını alırken güncelle
    const currentDocumentType = requestData.requestedDocumentType; // Değişti
    const currentStatus = requestData.currentStatus;
    const userInput = requestData.userInput;
    const currentCollectedData = requestData.currentCollectedData;
    const chatId = requestData.chatId;

    // Supabase ve LLM Anahtarları (API_KEY_SECRET_NAME güncellendi)
    const apiKey = Deno.env.get(API_KEY_SECRET_NAME);
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    if (!apiKey || !supabaseUrl || !supabaseAnonKey) {
      throw new Error('Missing API Key or Supabase credentials in environment variables.');
    }
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey);
    let responsePayload = {};

    // --- Duruma Göre İş Mantığı --- (Parametreler güncellendi)
    switch(currentStatus){
      case 'idle':
        {
          console.log("Processing Idle State...");
          const intentDetectionPrompt = `
          Kullanıcı mesajını analiz et: "${userInput}"
          Bu mesajın temel amacı nedir? Aşağıdaki JSON formatında cevap ver:
          {
            "intent": "<intent>", // Olası değerler: "question", "create_document", "greeting", "unknown", "clarify_document"
            "documentType": "<document_type>" // Eğer intent "create_document" ise tahmin edilen belge türü ID'si (örn: "kira_sozlesmesi", "ihtarname"). Diğer durumlarda null.
          }`; // templateId -> documentType
          const intentResult = await callOpenAI([
            { role: 'system', content: 'Kullanıcının niyetini analiz et ve JSON döndür.' },
            { role: 'user', content: intentDetectionPrompt }
          ], apiKey, 0.3, 150, true);

          if (intentResult.intent === 'create_document' && intentResult.documentType) {
            const documentType = intentResult.documentType; 
            const templateDetails = await getTemplateDetails(documentType, supabaseClient);
            if (!templateDetails) {
              responsePayload = {
                responseText: `"${documentType}" için bir şablon bulamadım ama isterseniz genel bilgilerle devam edebiliriz. Hangi bilgileri eklememi istersiniz?`,
                newStatus: 'collectingInfo',
                documentType: documentType, 
                collectedData: {},
                isAskingQuestion: true,
              };
            } else {
              const firstQuestionPrompt = `
Bir "${templateDetails.name}" belgesi oluşturmaya yardımcı oluyorum.
Bu belge için gerekli bilgiler şunlardır: ${JSON.stringify(templateDetails.fields.map((f)=>f.label + (f.required ? ' (Zorunlu)' : '')))}.
Kullanıcıdan bilgi toplamaya başlamak için sormam gereken ilk uygun soruyu oluştur.
Yanıtın SADECE sorunun metni olmalı, başka hiçbir şey içermemeli. Örneğin: "Kiracının adı ve soyadı nedir?"`;
              const firstQuestion = await callOpenAI([
                 { role: 'system', content: 'Belge oluşturmaya yardımcı asistansın. Kullanıcıya sorulacak ilk soruyu üret.' },
                 { role: 'user', content: firstQuestionPrompt }
              ], apiKey, 0.5, 100);
              responsePayload = {
                responseText: firstQuestion,
                newStatus: 'collectingInfo',
                documentType: documentType,
                collectedData: {},
                isAskingQuestion: true
              };
            }
          } else if (intentResult.intent === 'question') {
              console.log("Intent: question. Generating general answer...");
              const systemPrompt = 'Sen genel konularda yardımcı olan, arkadaş canlısı bir yapay zeka asistanısın.'; // Daha genel bir system prompt
              const normalAnswer = await callOpenAI([
                 { role: 'system', content: systemPrompt },
                 { role: 'user', content: userInput }
              ], apiKey, 0.7, 400); // Daha yaratıcı cevap için sıcaklık artırıldı
              responsePayload = {
                responseText: normalAnswer,
                newStatus: 'idle',
              };
          } else if (intentResult.intent === 'greeting') {
              console.log("Intent: greeting. Sending predefined greeting...");
              responsePayload = {
                responseText: "Merhaba! Size nasıl yardımcı olabilirim? Hukuki bir belge oluşturmak mı istersiniz, yoksa başka bir sorunuz mu var?", // Daha açıklayıcı selamlama
                newStatus: 'idle',
              };
          } else {
              console.log(`Intent: ${intentResult.intent || 'unknown'}. Sending clarification message...`);
              responsePayload = {
                responseText: "Ne yapmak istediğinizi tam olarak anlayamadım. Belirli bir hukuki belge mi oluşturmak istiyorsunuz, yoksa genel bir sorunuz mu var?",
                newStatus: 'idle',
              };
          }
          break;
        }
      case 'collectingInfo':
        {
          console.log("Processing CollectingInfo State...");
          // Gelen parametre adını kontrol et
          if (!currentDocumentType) throw new Error("collectingInfo statusunda requestedDocumentType eksik.");
          // getTemplateDetails'e documentType gönder
          const templateDetails = await getTemplateDetails(currentDocumentType, supabaseClient);
          // Şablon bulunamasa bile devam et, sadece alan listesi boş olur
          const fieldsDescription = templateDetails 
             ? JSON.stringify(templateDetails.fields.map((f)=>({ key: f.key, label: f.label, type: f.type, required: f.required }))) 
             : "(Şablon bulunamadı, genel bilgiler toplanıyor)";
          const documentName = templateDetails ? templateDetails.name : currentDocumentType;

          const extractionPrompt = `
          Sen bir hukuki belge için bilgi toplayan asistansın.
          Belge Türü/Adı: ${documentName}
          Gerekli Alanlar (varsa): ${fieldsDescription}
          Şu Ana Kadar Toplananlar (key: value): ${JSON.stringify(currentCollectedData)}
          Kullanıcının Son Cevabı/Açıklaması: "${userInput}"
          Görev: Kullanıcının cevabından ilgili bilgileri çıkar ve mevcut bilgileri JSON formatında güncelle. Eğer şablondan gelen zorunlu alanlar varsa ve hepsi toplandıysa 'done' durumunu, eksik varsa bir sonraki mantıklı soruyu sorarak 'continue' durumunu, cevap anlaşılamazsa 'clarify' durumunu JSON olarak döndür. Eğer şablon yoksa, kullanıcı yeterli bilgi verdiğini düşünüyorsa 'done', daha fazla bilgi eklemek isterse 'continue' durumunu döndür.
          JSON Formatları:
          {"status": "done", "updatedData": {...}}
          {"status": "continue", "updatedData": {...}, "nextQuestion": "..."}
          {"status": "clarify", "updatedData": ${JSON.stringify(currentCollectedData)}, "nextQuestion": "Anlayamadım, ... ile ilgili bilgiyi tekrar verebilir misiniz?"}`; // Clarify prompt iyileştirildi
          
          const extractionResult = await callOpenAI([
            { role: 'system', content: 'Bilgi toplayan asistansın. JSON döndür.' },
            { role: 'user', content: extractionPrompt }
          ], apiKey, 0.4, 500, true);

          if (extractionResult.status === 'done') {
            const finalData = extractionResult.updatedData || currentCollectedData;
            const summaryPrompt = `
            '${documentName}' için şu bilgiler toplandı:
            ${Object.entries(finalData).map(([key, value])=>`- ${templateDetails?.fields.find((f)=>f.key === key)?.label || key}: ${value}`).join('\n')}
            Kullanıcıya bu bilgileri özetle ve doğruluğunu sor. Eksik veya yanlış varsa belirtmesini iste.`; // Özet prompt iyileştirildi
            const summaryText = await callOpenAI([
              { role: 'system', content: 'Toplanan bilgileri özetle ve onay iste.' },
              { role: 'user', content: summaryPrompt }
            ], apiKey); // Sıcaklık, token, JSON modu belirtilmemiş, varsayılanları kullanır
            responsePayload = {
              responseText: summaryText,
              newStatus: 'awaitingConfirmation',
              documentType: currentDocumentType, // Değişti
              collectedData: finalData,
              isAskingQuestion: false
            };
          } else if (extractionResult.status === 'continue' || extractionResult.status === 'clarify') {
            responsePayload = {
              responseText: extractionResult.nextQuestion,
              collectedData: extractionResult.updatedData || currentCollectedData,
              newStatus: 'collectingInfo',
              documentType: currentDocumentType, // Değişti
              isAskingQuestion: true
            };
          } else { /* ... (hata durumu aynı) ... */ }
          break;
        }
      case 'awaitingConfirmation':
        {
          console.log("Processing AwaitingConfirmation State...");
          // Kullanıcı mesajına göre onay/ret işlemini burada yapabiliriz (TODO)
          // Şimdilik sadece butonları kullanmaya yönlendiriyor
          responsePayload = {
            responseText: "Bilgileri onaylamak veya düzenlemek isterseniz belirtebilirsiniz. Onaylamak için aşağıdaki butonu kullanın.", // Mesaj güncellendi
            newStatus: 'awaitingConfirmation',
            documentType: currentDocumentType, // Değişti
            collectedData: currentCollectedData,
            isAskingQuestion: false
          };
          break;
        }
      default: /* ... (aynı) ... */
    }
    console.log("Sending Response:", responsePayload);

    // Eğer payload boşsa, varsayılan bir yanıt ekle
    if (Object.keys(responsePayload).length === 0) {
       console.warn("Response payload was empty, returning default idle response.");
       responsePayload = {
         responseText: "Nasıl yardımcı olabilirim?",
         newStatus: 'idle',
         // Diğer alanlar null kalır
       };
    }

    return new Response(JSON.stringify(responsePayload), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) { /* ... (hata yönetimi aynı) ... */ }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/process-chat-turn' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
