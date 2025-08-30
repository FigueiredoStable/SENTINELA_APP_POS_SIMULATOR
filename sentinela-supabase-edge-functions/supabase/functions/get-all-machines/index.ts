// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"; // Adjust the version as needed

const supabaseUrl = Deno.env.get("SUPABASE_URL"); // Set your Supabase URL in environment variables
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY"); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);

Deno.serve(async (req) => {

  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  }

    // This is needed if you're planning to invoke your function from a browser.
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: headers })
    }

  const { schemaName} = await req.json()

  const { data: machines, error: fetchError } = await supabase
  .schema(schemaName)
  .from('machines')
  .select('id, name, address, app_id, available, blocked, registered, price_options');

  if (fetchError) {
    return new Response(JSON.stringify({ message: 'Erro de comunicação, Tente novamente' , error: fetchError.message }), {
      status: 500,
      headers,
    });
  }
  if (!machines || machines.length === 0) {
    return new Response(
      JSON.stringify({ message: 'Nenhuma Máquina Disponível' }),
      { status: 404, headers }
    );
  }


  return new Response(JSON.stringify({'machines' : machines}), {
    status: 200,
    headers,
  });
})
