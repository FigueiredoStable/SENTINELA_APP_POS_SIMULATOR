import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2'; // Adjust the version as needed

const supabaseUrl = Deno.env.get('SUPABASE_URL'); // Set your Supabase URL in environment variables
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY'); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);

Deno.serve(async (req) => {
  const { client_serial } = await req.json();

  const { data: client, error: fetchError } = await supabase
    .from('clients')
    .select('client_serial, id')
    .eq('client_serial', client_serial)
    .single();

  if (!client) {
    return new Response(
      JSON.stringify({ message: 'Serial Inválida', error: fetchError.message }),
      { status: 404, headers: { 'Content-Type': 'application/json' } },
    );
  }

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

  // TODO : retornar apenas o client uuid por segurança
  return new Response(
    JSON.stringify({
      message: 'Cliente encontrado',
      data: client,
    }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    },
  );
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/sentinela-register-pos-by-client' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
