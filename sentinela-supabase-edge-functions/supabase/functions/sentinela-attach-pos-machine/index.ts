// @ts-nocheck
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2'; // Adjust the version as needed

const supabaseUrl = Deno.env.get('SUPABASE_URL'); // Set your Supabase URL in environment variables
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY'); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);

Deno.serve(async (req) => {
  const {
    client,
    machine_id,
    app_id,
    pos_device_specs,
    sentinela_apk_package_info,
  } = await req.json();

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
        success: false,
        message: 'Tente novamente',
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
        success: false,
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
  const { data: machine, error: fetchError } = await supabase
    .schema(client_data.client_schema)
    .from('machines')
    .select('*, machine_type(*)')
    .eq('id', machine_id)
    .single();

  if (fetchError) {
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Falha de conexão, Tente novamente',
        error: fetchError.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  if (!machine) {
    return new Response(JSON.stringify(
      {
      success: false,
      message: 'Máquina não encontrada'
    }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Update the 'app_id' and 'registered' columns
  const { error: updateError } = await supabase
    .schema(client_data.client_schema)
    .from('machines')
    .update({
      app_id: app_id,
      registered: true,
      available: false,
      pos_device_specs: pos_device_specs ?? {},
      sentinela_apk_package_info: sentinela_apk_package_info ?? {},
      interface_mac_address: '00:00:00:00:00:00',
    })
    .eq('id', machine.id);

  if (updateError) {
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Falha ao registrar, Tente novamente',
        error: updateError.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  return new Response(JSON.stringify(
    {
      success: true,
      message: 'Máquina registrada com sucesso',
      machine: machine
    }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/sentinela-attach-pos-machine' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
