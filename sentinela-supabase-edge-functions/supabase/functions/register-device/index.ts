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
  const { schema, user_serial, app_id, machine_id, pos_device_specs, sentinela_apk_package_info } =
    await req.json();

  // Check if the serial exists in the 'node' table
  const { data: machine, error: fetchError } = await supabase
    .schema(schema)
    .from('machines')
    .select('id, name')
    .eq('id', machine_id)
    .single();

  if (fetchError) {
    return new Response(
      JSON.stringify({
        message: 'Falha de conexão, Tente novamente',
        error: fetchError.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  if (!machine) {
    return new Response(JSON.stringify({ message: 'Máquina não encontrada' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Update the 'app_id' and 'registered' columns
  const { error: updateError } = await supabase
    .schema(schema)
    .from('machines')
    .update({
      app_id: app_id,
      registered: true,
      available: false,
      pos_device_specs: pos_device_specs,
      sentinela_apk_package_info: sentinela_apk_package_info,
    })
    .eq('id', machine_id);

  if (updateError) {
    return new Response(
      JSON.stringify({ message: 'Falha ao registrar, Tente novamente' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  return new Response(JSON.stringify(machine), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
