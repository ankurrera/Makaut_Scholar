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

        const authHeader = req.headers.get('Authorization');
        if (!authHeader) throw new Error('Missing Authorization header');

        const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

        // 1. Verify identity of the user requesting deletion
        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''));

        if (authError || !user) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
            );
        }

        const userId = user.id;

        // 2. Delete User Data (Database)
        // Note: CASCADE should handle most things if FKs are set, but let's be explicit

        // Delete Profile Photos (Storage)
        try {
            const { data: files } = await supabaseClient.storage.from('avatars').list(userId);
            if (files && files.length > 0) {
                const paths = files.map(f => `${userId}/${f.name}`);
                await supabaseClient.storage.from('avatars').remove(paths);
            }
        } catch (e) {
            console.error('Error deleting avatar files:', e);
        }

        // Delete from DB tables (Profiles and Purchases)
        const { error: profileError } = await supabaseClient.from('profiles').delete().eq('id', userId);
        const { error: purchasesError } = await supabaseClient.from('user_purchases').delete().eq('user_id', userId);
        const { error: ordersError } = await supabaseClient.from('orders').delete().eq('user_id', userId);

        if (profileError || purchasesError || ordersError) {
            console.error('DB Deletion Error:', { profileError, purchasesError, ordersError });
        }

        // 3. Delete the Auth User (Final Step)
        const { error: deleteUserError } = await supabaseClient.auth.admin.deleteUser(userId);

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
