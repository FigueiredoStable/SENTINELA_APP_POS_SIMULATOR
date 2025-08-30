// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// @ts-nocheck
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2'; // Adjust the version as needed
const supabaseUrl = Deno.env.get('SUPABASE_URL'); // Set your Supabase URL in environment variables
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY'); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);
Deno.serve(async (req) => {
  const {
    client,
    machine,
    command_description,
    interface_response,
    interface_epoch_timestamp,
    executed,
    //timestamp,
    event_id,
  } = await req.json();
  // Check if the request is valid
  if (
    client == null ||
    machine == null ||
    command_description == null ||
    interface_response == null ||
    interface_epoch_timestamp == null ||
    executed == null ||
    event_id == null
  ) {
    return new Response(
      JSON.stringify({ message: 'Dados inválidos, Tente novamente' }),
      {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
        },
      },
    );
  }
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
  // Check if the machine exists in the 'machines' table in the client's schema
  const { data: machine_data, error: fetchError } = await supabase
    .schema(client_data.client_schema)
    .from('machines')
    .select('id')
    .eq('id', machine)
    .limit(1)
    .single();
  if (fetchError) {
    return new Response(
      JSON.stringify({
        message: 'Ocorreu um erro, Tente novamente',
        error: fetchError.message,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
        },
      },
    );
  }
  if (!machine_data) {
    return new Response(
      JSON.stringify({
        message: 'Máquina não encontrada',
      }),
      {
        status: 404,
        headers: {
          'Content-Type': 'application/json',
        },
      },
    );
  }

  // Check if the command event already exists in the 'command_events' table, if so, update it
  const { error: updateError } = await supabase
    .schema(client_data.client_schema)
    .from('command_events')
    .upsert(
      {
        id: event_id,
        command_description: command_description,
        interface_response: interface_response,
        interface_epoch_timestamp: interface_epoch_timestamp,
        local_event_id: event_id,
        executed: executed,
      },
      { onConflict: ['id'] },
    );

  if (updateError) {
    return new Response(
      JSON.stringify({
        message: 'Falha ao registrar, Tente novamente',
        error: updateError.message,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
        },
      },
    );
  }

  const response = {
    success: true,
    message: 'Command event registered successfully',
  };
  return new Response(JSON.stringify(response), {
    headers: {
      'Content-Type': 'application/json',
    },
  });
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/sentinela-command-event' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
