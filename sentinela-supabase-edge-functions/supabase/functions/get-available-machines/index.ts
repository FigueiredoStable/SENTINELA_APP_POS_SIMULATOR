// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2'; // Adjust the version as needed

const supabaseUrl = Deno.env.get('SUPABASE_URL'); // Set your Supabase URL in environment variables
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY'); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);

Deno.serve(async (req) => {
  const { schemaName } = await req.json();

  const { data: machines, error: fetchError } = await supabase
    .schema(schemaName)
    .from('machines')
    .select('id, name', 'address', 'machine_type')
    .eq('available', true);

  if (fetchError) {
    return new Response(
      JSON.stringify({
        message: 'Erro de comunicação, Tente novamente',
        error: fetchError.message,
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }
  if (!machines || machines.length === 0) {
    return new Response(
      JSON.stringify({ message: 'Nenhuma Máquina Disponível' }),
      { status: 404, headers: { 'Content-Type': 'application/json' } },
    );
  }

  return new Response(JSON.stringify({ machines: machines }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
