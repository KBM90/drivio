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
        const firebaseServiceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

        if (!firebaseServiceAccountRaw) {
            console.error('❌ FIREBASE_SERVICE_ACCOUNT environment variable is not set')
            throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is missing. Please configure it in Supabase Dashboard.')
        }

        let serviceAccount: any
        try {
            serviceAccount = JSON.parse(firebaseServiceAccountRaw)
        } catch (parseError) {
            console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT:', parseError)
            console.error('Raw value length:', firebaseServiceAccountRaw.length)
            console.error('First 100 chars:', firebaseServiceAccountRaw.substring(0, 100))
            throw new Error('FIREBASE_SERVICE_ACCOUNT contains invalid JSON. Please check the format.')
        }

        if (!serviceAccount.project_id || !serviceAccount.private_key || !serviceAccount.client_email) {
            console.error('❌ FIREBASE_SERVICE_ACCOUNT is missing required fields')
            console.error('Has project_id:', !!serviceAccount.project_id)
            console.error('Has private_key:', !!serviceAccount.private_key)
            console.error('Has client_email:', !!serviceAccount.client_email)
            throw new Error('FIREBASE_SERVICE_ACCOUNT is missing required fields (project_id, private_key, client_email)')
        }

        // Get OAuth2 access token for FCM
        const accessToken = await getAccessToken(serviceAccount)

        // Send FCM notification
        const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

        // Convert data to string key-value pairs (FCM requirement)
        const fcmData: Record<string, string> = {}
        if (data && typeof data === 'object') {
            for (const [key, value] of Object.entries(data)) {
                fcmData[key] = typeof value === 'string' ? value : JSON.stringify(value)
            }
        }

        const message = {
            message: {
                token: fcm_token,
                notification: {
                    title: title,
                    body: body,
                },
                data: fcmData,
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
    // Helper function for URL-safe base64 encoding (without padding)
    function base64UrlEncode(str: string): string {
        const base64 = btoa(str)
        return base64
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '')
    }

    function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
        const bytes = new Uint8Array(buffer)
        let binary = ''
        for (let i = 0; i < bytes.length; i++) {
            binary += String.fromCharCode(bytes[i])
        }
        return base64UrlEncode(binary)
    }

    const jwtHeader = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))

    const now = Math.floor(Date.now() / 1000)
    const jwtClaimSet = {
        iss: serviceAccount.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        exp: now + 3600,
        iat: now,
    }

    const jwtClaimSetEncoded = base64UrlEncode(JSON.stringify(jwtClaimSet))
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

    const signatureEncoded = arrayBufferToBase64Url(signature)
    const jwt = `${signatureInput}.${signatureEncoded}`

    console.log('🔑 Generated JWT token (first 50 chars):', jwt.substring(0, 50))

    // Exchange JWT for access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    })

    if (!tokenResponse.ok) {
        const errorText = await tokenResponse.text()
        console.error('❌ OAuth2 token exchange failed:', errorText)
        throw new Error(`Failed to get OAuth2 token: ${errorText}`)
    }

    const tokenData = await tokenResponse.json()
    console.log('✅ Successfully obtained OAuth2 access token')
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
