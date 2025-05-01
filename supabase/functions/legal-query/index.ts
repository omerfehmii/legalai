// @deno-types="https://esm.sh/v135/@supabase/functions-js@2.3.1/src/edge-runtime.d.ts"
// Follow this pattern to import other npm modules
// https://deno.land/manual@v1.41.0/basics/modules/npm_specifiers
import OpenAI from 'https://esm.sh/openai@4.12.4';
import { corsHeaders } from '../_shared/cors.ts';

// Define expected input structure
interface RequestPayload {
  history: Array<{ role: 'user' | 'assistant'; content: string }>;
  currentStatus: string; // e.g., "idle", "collectingInfo", "awaitingConfirmation"
  requestedDocumentType?: string | null;
  currentCollectedData?: Record<string, string> | null;
}

// Define the structure AI should provide in its response metadata
interface ResponseMetadata {
  isAskingQuestion: boolean;
  nextStatus: string; // e.g., "idle", "collectingInfo", "awaitingConfirmation"
  updatedCollectedData?: Record<string, string> | null;
  // documentType might be confirmed/set by AI
  documentType?: string | null;
}

const HISTORY_SUMMARIZATION_THRESHOLD = 10; // Summarize if history exceeds this many messages
const HISTORY_RECENT_MESSAGES_KEPT = 4;   // Keep this many recent messages when summarizing
const MAX_MESSAGES_TO_SUMMARIZE = 40;     // Limit the number of messages sent for summarization
const MAIN_MODEL = 'gpt-4.1-mini-2025-04-14';
const SUMMARIZATION_MODEL = 'gpt-4.1-nano-2025-04-14';

// Function to build the dynamic system prompt
function buildSystemPrompt(status: string, docType?: string | null, collectedData?: Record<string, string> | null): string {
  // Persona Change: More like a conversational lawyer simulation
  let basePrompt = `Sen, kullanıcılarla bir avukat gibi sohbet eden, onların hukuki durumlarını anlamaya çalışan ve olası adımlar hakkında ön bilgi veren bir avukatsın.
Amacın, kullanıcıyı bilgilendirmek ve bir sonraki adımları netleştirmesine yardımcı olmak. Empatik, sabırlı ve profesyonel bir üslup kullan.

Türkçe karakterleri doğru kullan ve resmi ama aynı zamanda anlaşılır bir dil kullan. Kod blokları dışındaki metinlerde Markdown kullanma.

ÖNEMLİ (YANIT FORMATI): Yanıtının sonuna HER ZAMAN şu formatta bir JSON bloğu ekle (başka hiçbir şey olmadan):
\\nRESPONSE_METADATA: { "isAskingQuestion": boolean, "nextStatus": "status_name", "updatedCollectedData": {...} }
// ... rest of the prompt ...
- isAskingQuestion: Kullanıcıya bir soru soruyorsan 'true', sormuyorsan 'false'.
- nextStatus: Bu yanıttan sonraki konuşma durumu ('idle', 'collectingInfo', 'awaitingConfirmation', 'generating', 'ready', 'failed').
- updatedCollectedData: Eğer kullanıcıdan yeni bilgi aldıysan veya mevcut bilgileri güncellediysen, bilgilerin SON HALİNİ içeren obje, yoksa null.

Görevlerin ve Duruma Göre Davranışların:`;

  // Add status-specific instructions
  switch (status) {
    case 'idle':
      basePrompt += `
1.  **Durumu Anlama:** Kullanıcının genel hukuki sorusunu veya durumunu anlamaya çalış. Gerekirse açıklayıcı sorular sor. \"Size nasıl yardımcı olabilirim?\" gibi genel bir giriş yap.
2.  **Belge Talebini Karşılama:** Kullanıcı spesifik bir belge (dilekçe, sözleşme vb.) istediğini belirtirse, \"Anlıyorum, [Belge Türü] hazırlama sürecini başlatabiliriz. Bunun için bazı bilgilere ihtiyacım olacak.\" gibi bir yanıt ver. Yanıtında isAskingQuestion: true, nextStatus: 'collectingInfo' olarak belirt.`;
      break;
    case 'collectingInfo':
      basePrompt += `
1.  **Bilgi Toplama (Danışman Tarzı):** Kullanıcının istediği '${docType || 'belge'}' için gerekli bilgileri topluyorsun. Mevcut veriler: ${JSON.stringify(collectedData || {})}. Eksik bilgileri sohbet havasında, tek tek iste. Örneğin: \"Peki, [Kiracı Adı] kim olacak?\" veya \"Anladım, [Tarih] bilgisini de alabilir miyim?\" gibi.
2.  **Akışı Sürdürme:** Kullanıcı bilgi verdiğinde, \"Tamamdır, not ettim.\" gibi kısa bir teyit ver ve bir sonraki eksik bilgiyi sor.
3.  **Onaya Hazırlık:** Tüm bilgiler toplandığında, \"Sanırım gerekli tüm bilgileri aldık. Şöyle bir özetleyelim: [Bilgilerin Özeti]. Bu bilgilerle devam edebilir miyiz?\" diye sor. nextStatus: 'awaitingConfirmation', isAskingQuestion: true olarak belirt.`;
      break;
    case 'awaitingConfirmation':
      basePrompt += `
1.  **Onay Bekleme:** Toplanan verileri (${JSON.stringify(collectedData || {})}) kullanıcıya sundun ve onayını bekliyorsun. "Bilgiler doğruysa belge taslağını hazırlayabilirim." gibi bir ifade kullan.
2.  **Onay Alındı:** Kullanıcı onay verirse, "Harika, onayınızla birlikte şimdi [Belge Türü] taslağını hazırlıyorum." de. nextStatus: 'generating', isAskingQuestion: false olarak belirt. Ardından, bu bilgilerle doldurulmuş belge metnini **\`\`\`legal-document ... \`\`\`** bloğu içinde ver.
3.  **Değişiklik Talebi:** Kullanıcı onay vermez veya değişiklik isterse, "Elbette, hangi bilgiyi düzeltmemi veya eklememi istersiniz?" diye sor. nextStatus: 'collectingInfo', isAskingQuestion: true olarak belirt.`;
      break;
    // Add cases for 'generating', 'ready', 'failed' if needed, though generation often happens elsewhere
    default:
      basePrompt += `
1.  Normal sohbete devam et, kullanıcının sorularını yanıtla veya durumu anlamaya çalış. Durumu ('${status}') göz önünde bulundurarak uygun şekilde yanıt ver.`;
  }

  basePrompt += `

Belge metinlerini (hem taslak hem doldurulmuş) oluşturduğunda HER ZAMAN **\`\`\`legal-document ... \`\`\`** bloğu içine yaz. Bu blok dışında ASLA belge metni yazma.`;

  return basePrompt;
}

// Helper function to summarize history
async function getHistorySummary(messagesToSummarize: Array<{ role: string; content: string }>, openai: OpenAI): Promise<string | null> {
  if (messagesToSummarize.length === 0) {
    return null;
  }
  console.log(`Summarizing ${messagesToSummarize.length} messages...`);
  try {
    const summarizationPrompt = `Aşağıdaki hukuki danışmanlık konuşmasının kısa bir özetini çıkar. Ana konuları, sorulan soruları ve verilen önemli bilgileri belirt. Özet, konuşmanın devamı için bağlam sağlayacak şekilde olmalı.

KONUŞMA:
${messagesToSummarize.map(m => `${m.role}: ${m.content}`).join('\n')}\n
ÖZET:`;

    const completion = await openai.chat.completions.create({
      model: SUMMARIZATION_MODEL,
      messages: [{ role: 'user', content: summarizationPrompt }],
      temperature: 0.3, // Keep summary factual
    });
    const summary = completion.choices[0]?.message?.content?.trim();
    console.log("Summary generated:", summary);
    return summary || null;
  } catch (error) {
    console.error("Error during summarization:", error);
    return null; // Return null if summarization fails
  }
}

// Use the original Deno.serve structure
Deno.serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: RequestPayload = await req.json();
    const { history, currentStatus, requestedDocumentType, currentCollectedData } = payload;

    // --- Input Validation (Keep the new extensive validation) ---
    if (!currentStatus || typeof currentStatus !== 'string') {
       return new Response(JSON.stringify({ error: 'Geçersiz veya eksik konuşma durumu (currentStatus) gönderildi' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (!Array.isArray(history)) { // history can be empty initially
      return new Response(JSON.stringify({ error: 'Geçersiz mesaj geçmişi (history) gönderildi' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (history.length > 0) {
        for (const msg of history) {
            if (!msg || typeof msg.role !== 'string' || typeof msg.content !== 'string' || (msg.role !== 'user' && msg.role !== 'assistant')) {
                return new Response(JSON.stringify({ error: 'Geçersiz mesaj formatı gönderildi' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
            }
        }
    }
    if (requestedDocumentType !== undefined && requestedDocumentType !== null && typeof requestedDocumentType !== 'string') {
      return new Response(JSON.stringify({ error: 'Geçersiz belge türü formatı (requestedDocumentType)' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    if (currentCollectedData !== undefined && currentCollectedData !== null && (typeof currentCollectedData !== 'object' || Array.isArray(currentCollectedData))) {
       return new Response(JSON.stringify({ error: 'Geçersiz toplanan veri formatı (currentCollectedData)' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
    }
    // --- End Validation ---

    // --- OpenAI Client (Use original setup) ---
    const openAiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openAiKey) {
        // Throwing error here was the original pattern, let's stick to it for now
        // unless console.error and returning Response is preferred system-wide.
       throw new Error('OPENAI_API_KEY bulunamadı');
    }
    const openai = new OpenAI({ apiKey: openAiKey });

    // --- Prepare messages for OpenAI (Summarization Logic with Limit) ---
    const systemPrompt = buildSystemPrompt(currentStatus, requestedDocumentType, currentCollectedData);
    let messagesForApi: Array<{ role: string; content: string | null }> = [
        { role: 'system', content: systemPrompt }
    ];
    let recentMessages = history; // Default to using full history if not summarizing

    if (history.length > HISTORY_SUMMARIZATION_THRESHOLD) {
      console.log(`History length (${history.length}) exceeds threshold (${HISTORY_SUMMARIZATION_THRESHOLD}). Attempting summarization.`);
      // Identify messages before the recent ones
      const potentialMessagesToSummarize = history.slice(0, -HISTORY_RECENT_MESSAGES_KEPT);
      recentMessages = history.slice(-HISTORY_RECENT_MESSAGES_KEPT); // Keep only recent messages
      
      // Apply the limit: Take only the last MAX_MESSAGES_TO_SUMMARIZE from the potential list
      const actualMessagesToSummarize = potentialMessagesToSummarize.slice(-MAX_MESSAGES_TO_SUMMARIZE);
      console.log(`Summarizing the last ${actualMessagesToSummarize.length} messages out of ${potentialMessagesToSummarize.length} eligible for summary.`);

      // Call summarization with the limited list
      const summary = await getHistorySummary(actualMessagesToSummarize, openai);

      if (summary) {
        // Add summary as a system message
        messagesForApi.push({ role: 'system', content: `Konuşmanın önceki ilgili kısmının özeti: ${summary}` }); // Slightly change prompt message
      } else {
        console.warn("Summarization failed or returned empty. Proceeding without summary.");
      }
    }
    
    // Add the recent messages
    messagesForApi.push(...recentMessages);

    // --- Call OpenAI (Use original call structure with MAIN_MODEL) ---
    const chatCompletion = await openai.chat.completions.create({
      model: MAIN_MODEL,
      messages: messagesForApi,
    });

    let aiRawAnswer = chatCompletion.choices[0]?.message?.content;

    // Handle potential null/empty response from OpenAI
    if (!aiRawAnswer) {
      // Return a more specific error than just "AI'dan yanıt alınamadı"
      console.error('OpenAI response content is null or empty.');
      return new Response(JSON.stringify({ error: 'AI yanıtı alınamadı veya boş geldi.' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 });
    }

    // --- Parse AI Response (Keep new logic) ---
    let responseText = aiRawAnswer;
    let responseMetadata: ResponseMetadata | null = null;
    const metadataMarker = '\\nRESPONSE_METADATA:';
    const markerIndex = aiRawAnswer.lastIndexOf(metadataMarker);

    if (markerIndex !== -1) {
      responseText = aiRawAnswer.substring(0, markerIndex).trim();
      const jsonString = aiRawAnswer.substring(markerIndex + metadataMarker.length).trim();
      try {
        const parsedJson = JSON.parse(jsonString);
        if (typeof parsedJson.isAskingQuestion === 'boolean' && typeof parsedJson.nextStatus === 'string') {
            responseMetadata = {
               isAskingQuestion: parsedJson.isAskingQuestion,
               nextStatus: parsedJson.nextStatus,
               updatedCollectedData: parsedJson.updatedCollectedData !== undefined ? parsedJson.updatedCollectedData : (currentCollectedData || null),
               documentType: parsedJson.documentType !== undefined ? parsedJson.documentType : (requestedDocumentType || null),
            };
        } else {
            console.warn('Parsed metadata JSON has incorrect structure:', jsonString);
        }
      } catch (e) {
        console.warn('Failed to parse metadata JSON:', jsonString, e);
      }
    } else {
      console.warn('Metadata marker not found in AI response.');
       responseMetadata = {
          isAskingQuestion: false,
          nextStatus: currentStatus,
          updatedCollectedData: currentCollectedData || null,
          documentType: requestedDocumentType || null,
       };
    }

    if (!responseMetadata) {
         console.error("Failed to determine response metadata after parsing attempt.");
         return new Response(JSON.stringify({ error: 'AI yanıtı işlenirken metadata oluşturulamadı.' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 });
     }

    // --- Return Structured Response (Keep new structure) ---
    return new Response(JSON.stringify({
      responseText: responseText,
      isAskingQuestion: responseMetadata.isAskingQuestion,
      newStatus: responseMetadata.nextStatus,
      documentType: responseMetadata.documentType,
      collectedData: responseMetadata.updatedCollectedData,
      documentPath: null,
      error: null
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    });

  } catch (error) {
    // Use original error handling structure
    console.error('Error in legal-query function:', error);
    return new Response(JSON.stringify({
      error: error.message || 'Bilinmeyen bir sunucu hatası oluştu'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500 // Keep original 500 for all catch block errors for now
    });
  }
});
