// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// @ts-ignore
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
// @ts-ignore
import { createClient } from 'jsr:@supabase/supabase-js'; // Adjust the version as needed

// @ts-ignore
const supabaseUrl = Deno.env.get('SUPABASE_URL'); // Set your Supabase URL in environment variables
// @ts-ignore
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY'); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);

// @ts-ignore
Deno.serve(async (req) => {
  const { client, machine_id, first_boot_time, sentinela_info } =
    await req.json();

  // Check if client_id is valid and get the schema from the 'users' table in the public schema
  const { data: client_data, error: clientError } = await supabase
    .schema('public')
    .from('clients')
    .select('client_schema, pos_activation_code')
    .eq('id', client)
    .limit(1)
    .single();
  if (clientError) {
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Cliente não encontrado.',
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
        message: 'Cliente não encontrado.',
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
    .select(
      'id, name, registered, blocked, available, price_options, counter_options, payments_types, support_information, interface_mac_address, operation_options, default_initialization_settings',
    )
    .eq('id', machine_id)
    .single();

  if (fetchError) {
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Erro ao buscar a máquina',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }

  if (!machine) {
    return new Response(
      JSON.stringify({ message: 'Máquina não encontrada no sistema' }),
      { status: 404, headers: { 'Content-Type': 'application/json' } },
    );
  }

  // update the machine with the first_boot_time
  const { error: updateError } = await supabase
    .schema(client_data.client_schema)
    .from('machines')
    .update({
      last_time_boot_epoch: first_boot_time,
      sentinela_apk_package_info: sentinela_info,
    })
    .eq('id', machine_id);
  if (updateError) {
    return new Response(
      JSON.stringify({
        success: false,
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

  // concat client activation code //TODO: this logic must be rethought, for example if the client havo more than one enterprise bank account
  machine['pos'] = client_data.pos_activation_code.toString();
  //machine['pos'] = client_data['pos_activation_code'];
  return new Response(
    JSON.stringify({
      success: true,
      message: 'Máquina encontrada',
      configuration: machine,
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/sentinela-validate-pos-settings' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
