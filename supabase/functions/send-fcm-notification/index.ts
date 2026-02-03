import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// This Edge Function sends FCM push notifications
// It's triggered by Database Webhooks when a new notification is inserted

interface WebhookPayload {
    type: 'INSERT' | 'UPDATE' | 'DELETE'
    table: string
    record: {
        id: string
        user_id: number
        title: string
        body: string
        data?: Record<string, any>
    }
    schema: string
    old_record: null | any
}

serve(async (req) => {
    try {
        // Parse webhook payload
        const payload: WebhookPayload = await req.json()

        console.log('📦 Webhook received:', payload.type, 'on table:', payload.table)

        if (payload.type !== 'INSERT' || payload.table !== 'notifications') {
            return new Response(
                JSON.stringify({ success: false, error: 'Invalid webhook event' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

        const { user_id, title, body, data } = payload.record

        // Initialize Supabase client
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        // Fetch user's FCM token from database
        const { data: tokenData, error: tokenError } = await supabase
            .from('user_fcm_tokens')
            .select('fcm_token')
            .eq('user_id', user_id)
            .single()

        if (tokenError || !tokenData) {
            console.log('⚠️ No FCM token found for user:', user_id)
            return new Response(
                JSON.stringify({ success: false, error: 'No FCM token found' }),
                { status: 404, headers: { 'Content-Type': 'application/json' } }
            )
        }

        const fcm_token = tokenData.fcm_token

        // Get Firebase service account from environment variable
        const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')

        if (!serviceAccount.project_id) {
            throw new Error('FIREBASE_SERVICE_ACCOUNT not configured')
        }

        // Get OAuth2 access token for FCM
        const accessToken = await getAccessToken(serviceAccount)

        // Send FCM notification
        const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

        const message = {
            message: {
                token: fcm_token,
                notification: {
                    title: title,
                    body: body,
                },
                data: data || {},
                android: {
                    priority: 'high',
                    notification: {
                        channel_id: 'general_notifications',
                        sound: 'default',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            },
        }

        const response = await fetch(fcmUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${accessToken}`,
            },
            body: JSON.stringify(message),
        })

        if (!response.ok) {
            const error = await response.text()
            console.error('FCM Error:', error)
            throw new Error(`FCM request failed: ${error}`)
        }

        const result = await response.json()
        console.log('✅ FCM notification sent:', result)

        return new Response(
            JSON.stringify({ success: true, result }),
            { headers: { 'Content-Type': 'application/json' } }
        )
    } catch (error) {
        console.error('❌ Error sending FCM notification:', error)
        return new Response(
            JSON.stringify({ success: false, error: error.message }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
    }
})

// Helper function to get OAuth2 access token
async function getAccessToken(serviceAccount: any): Promise<string> {
    const jwtHeader = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))

    const now = Math.floor(Date.now() / 1000)
    const jwtClaimSet = {
        iss: serviceAccount.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        exp: now + 3600,
        iat: now,
    }

    const jwtClaimSetEncoded = btoa(JSON.stringify(jwtClaimSet))
    const signatureInput = `${jwtHeader}.${jwtClaimSetEncoded}`

    // Import private key
    const privateKey = await crypto.subtle.importKey(
        'pkcs8',
        pemToArrayBuffer(serviceAccount.private_key),
        { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
        false,
        ['sign']
    )

    // Sign JWT
    const signature = await crypto.subtle.sign(
        'RSASSA-PKCS1-v1_5',
        privateKey,
        new TextEncoder().encode(signatureInput)
    )

    const jwt = `${signatureInput}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`

    // Exchange JWT for access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    })

    const tokenData = await tokenResponse.json()
    return tokenData.access_token
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
    const b64 = pem
        .replace(/-----BEGIN PRIVATE KEY-----/, '')
        .replace(/-----END PRIVATE KEY-----/, '')
        .replace(/\s/g, '')

    const binary = atob(b64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i)
    }
    return bytes.buffer
}
