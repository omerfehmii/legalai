# Legal Query Function

Bu Supabase edge function, hukuki sorulara OpenAI'nin GPT-4 modelini kullanarak yanıt vermek için tasarlanmıştır.

## Kurulum

1. Supabase'te OPENAI_API_KEY değişkenini ayarlayın:

```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

## Kullanım

Bu API uç noktası, bir hukuki soruyu alır ve ChatGPT kullanarak yanıtlar.

### İstek

```http
POST /functions/v1/legal-query
Content-Type: application/json
Authorization: Bearer YOUR_SUPABASE_ANON_KEY

{
  "query": "İş sözleşmesi feshedilirken nelere dikkat edilmelidir?"
}
```

### Yanıt

```json
{
  "answer": "İş sözleşmesinin feshi sırasında dikkat edilmesi gereken hususlar şunlardır:..."
}
```

## Yerel Geliştirme

Fonksiyonu yerel olarak çalıştırmak için:

```bash
supabase functions serve legal-query --env-file .env.local
```

`.env.local` dosyasında OPENAI_API_KEY değişkenini tanımlamalısınız. 