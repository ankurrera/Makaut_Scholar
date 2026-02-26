// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
        const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

        // Parse request body for the token
        const body = await req.json().catch(() => ({}));
        const userToken = body.userToken;

        if (!userToken) {
            return new Response(
                JSON.stringify({ error: 'Missing userToken in request body' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
            );
        }

        // Authenticate the user checking their token against Supabase using anon key
        const authClient = createClient(supabaseUrl, supabaseAnonKey);

        // 1. Verify identity of the user requesting deletion
        const { data: { user }, error: authError } = await authClient.auth.getUser(userToken);

        if (authError || !user) {
            return new Response(
                JSON.stringify({ error: authError ? authError.message : 'Unauthorized' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
            );
        }

        const userId = user.id;

        // Admin client with service role key to bypass RLS and delete user
        const adminClient = createClient(supabaseUrl, supabaseServiceKey);

        // 2. Delete User Data (Database)
        // Note: CASCADE should handle most things if FKs are set, but let's be explicit

        // Delete Profile Photos (Storage)
        try {
            const { data: files } = await adminClient.storage.from('avatars').list(userId);
            if (files && files.length > 0) {
                const paths = files.map(f => `${userId}/${f.name}`);
                await adminClient.storage.from('avatars').remove(paths);
            }
        } catch (e) {
            console.error('Error deleting avatar files:', e);
        }

        // Delete from DB tables (Profiles and Purchases)
        const { error: profileError } = await adminClient.from('profiles').delete().eq('id', userId);
        const { error: purchasesError } = await adminClient.from('user_purchases').delete().eq('user_id', userId);
        const { error: ordersError } = await adminClient.from('orders').delete().eq('user_id', userId);

        if (profileError || purchasesError || ordersError) {
            console.error('DB Deletion Error:', { profileError, purchasesError, ordersError });
        }

        // 3. Delete the Auth User (Final Step)
        const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(userId);

        if (deleteUserError) {
            throw new Error(`Auth deletion failed: ${deleteUserError.message}`);
        }

        return new Response(
            JSON.stringify({ success: true, message: 'Account and associated data deleted successfully.' }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        );

    } catch (error) {
        console.error(error);
        return new Response(
            JSON.stringify({ error: (error as Error).message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        );
    }
})
