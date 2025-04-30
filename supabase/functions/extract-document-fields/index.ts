// Edge function that extracts document field values from user description
// Using OpenAI API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.5.0';
import { OpenAI } from "https://esm.sh/openai@4.0.0";

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: Deno.env.get('OPENAI_API_KEY')!,
});

interface DocumentField {
  key: string;
  label: string;
  type: string;
  required: boolean;
}

interface DocumentTemplate {
  id: string;
  name: string;
  fields: DocumentField[];
  extractionPromptHint?: string;
}

interface RequestPayload {
  description: string;
  template: DocumentTemplate;
}

serve(async (req: Request) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    });
  }

  try {
    // Validate request method
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    // Parse request body
    const payload = await req.json() as RequestPayload;
    
    // Validate payload
    if (!payload.description || !payload.template || !payload.template.fields) {
      return new Response(JSON.stringify({ error: 'Invalid request payload' }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    // Extract fields from the description
    const extractedFields = await extractFieldsFromDescription(
      payload.description,
      payload.template
    );

    // Return extracted fields
    return new Response(JSON.stringify({ extractedFields }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error) {
    console.error('Error processing request:', error);
    
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
});

async function extractFieldsFromDescription(
  description: string,
  template: DocumentTemplate
): Promise<Record<string, any>> {
  // Create a structure for the prompt that explains what we need
  const fieldsInfo = template.fields.map(field => {
    return `- ${field.label} (${field.key}): ${field.type === 'date' ? 'Tarih (GG.AA.YYYY formatında)' : 
      field.type === 'number' ? 'Sayı' : 'Metin'}${field.required ? ' (Zorunlu)' : ''}`;
  }).join('\n');

  // Prepare system prompt
  const systemPrompt = `Sen bir hukuki belge bilgilerini çıkaran uzman bir asistandır. 
Kullanıcının verdiği açıklamadan aşağıda belirtilen alanlar için bilgileri çıkarman gerekiyor.

Belge Türü: ${template.name}
${template.extractionPromptHint ? `Belge Amacı: ${template.extractionPromptHint}` : ''}

Çıkarılacak alanlar:
${fieldsInfo}

Bilgileri JSON formatında döndür. Eğer bir bilgi bulunamazsa, ilgili alan için null değeri ver.
Tarih alanları için GG.AA.YYYY formatını kullan (örn: 01.05.2023).
Sayılar için ondalık ayracı olarak nokta kullan (örn: 1500.50).

Cevabında sadece JSON döndür, başka açıklama ekleme.`;

  // Call OpenAI API
  const response = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: description }
    ],
    temperature: 0.2, // Lower temperature for more consistent output
  });

  // Extract and parse the JSON response
  const aiResponse = response.choices[0]?.message?.content || '{}';
  
  try {
    // Try to parse the JSON from the response
    let extractedData: Record<string, any> = {};
    
    // Clean the response to extract only JSON
    const jsonMatch = aiResponse.match(/({[\s\S]*})/);
    if (jsonMatch) {
      extractedData = JSON.parse(jsonMatch[0]);
    } else {
      extractedData = JSON.parse(aiResponse);
    }
    
    // Process extracted data based on field types
    const processedData: Record<string, any> = {};
    
    template.fields.forEach(field => {
      const value = extractedData[field.key];
      
      if (value === undefined || value === null) {
        processedData[field.key] = null;
        return;
      }
      
      if (field.type === 'number') {
        // Convert to number if possible
        const numValue = parseFloat(String(value).replace(',', '.'));
        processedData[field.key] = isNaN(numValue) ? value : numValue;
      } else if (field.type === 'date') {
        // Keep date as string in DD.MM.YYYY format
        processedData[field.key] = value;
      } else {
        // Text fields
        processedData[field.key] = value;
      }
    });
    
    return processedData;
  } catch (error) {
    console.error('Error parsing AI response:', error);
    console.log('AI response was:', aiResponse);
    throw new Error('Failed to parse AI response');
  }
} 