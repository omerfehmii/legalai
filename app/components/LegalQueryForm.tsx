'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Loader2 } from 'lucide-react'
import { useToast } from '@/components/ui/use-toast'

export default function LegalQueryForm() {
  const [query, setQuery] = useState('')
  const [answer, setAnswer] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const { toast } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!query.trim()) {
      toast({
        title: 'Hata',
        description: 'Lütfen bir soru girin',
        variant: 'destructive',
      })
      return
    }

    setIsLoading(true)
    setAnswer('')

    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/legal-query`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY}`,
          },
          body: JSON.stringify({ query }),
        }
      )

      const data = await response.json()
      
      if (!response.ok) {
        throw new Error(data.error || 'Bir hata oluştu')
      }

      setAnswer(data.answer)
    } catch (error) {
      toast({
        title: 'Hata',
        description: error instanceof Error ? error.message : 'Bir hata oluştu',
        variant: 'destructive',
      })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="container max-w-4xl mx-auto py-6">
      <Card>
        <CardHeader>
          <CardTitle>Hukuki Soru Sor</CardTitle>
          <CardDescription>
            Türk hukuku ile ilgili sorularınızı yanıtlayalım
          </CardDescription>
        </CardHeader>
        <form onSubmit={handleSubmit}>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="query">Sorunuz</Label>
              <Textarea
                id="query"
                placeholder="Hukuki sorunuzu buraya yazın..."
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="min-h-[120px]"
                disabled={isLoading}
              />
            </div>

            {answer && (
              <div className="space-y-2 mt-6">
                <Label>Yanıt</Label>
                <Card className="p-4 bg-muted/50">
                  <div className="whitespace-pre-wrap">{answer}</div>
                </Card>
              </div>
            )}
          </CardContent>
          <CardFooter>
            <Button type="submit" disabled={isLoading || !query.trim()}>
              {isLoading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Yanıt alınıyor...
                </>
              ) : (
                'Soru Sor'
              )}
            </Button>
          </CardFooter>
        </form>
      </Card>
    </div>
  )
} 