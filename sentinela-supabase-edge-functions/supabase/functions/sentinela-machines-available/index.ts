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
  const { client } = await req.json();

  // Check if client_id is valid and get the schema from the 'users' table in the public schema
  const { data: client_data, error: clientError } = await supabase
    .schema('public')
    .from('clients')
    .select('client_schema')
    .eq('id', client)
    .limit(1)
    .single();
  if (clientError) {
    return new Response(
      JSON.stringify({
        message: 'Falha de conexão, Tente novamente',
        error: clientError.message,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
        },
      },
    );
  }
  if (!client_data) {
    return new Response(
      JSON.stringify({
        message: 'Cliente não encontrado',
      }),
      {
        status: 404,
        headers: {
          'Content-Type': 'application/json',
        },
      },
    );
  }

  // get the machines from the 'machines' table in the client's schema
  const { data: machines, error: fetchError } = await supabase
    .schema(client_data.client_schema)
    .from('machines')
    .select('id, name, address, machine_type(*)')
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

  return new Response(
    JSON.stringify({
      message: 'Máquinas disponíveis',
      machines: machines,
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/sentinela-machines-available' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
