import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2'; // Adjust the version as needed

const supabaseUrl = Deno.env.get('SUPABASE_URL'); // Set your Supabase URL in environment variables
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY'); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);

Deno.serve(async (req) => {
  const { user_serial } = await req.json();

  const { data: scheme, error: fetchError } = await supabase
    .from('clients')
    .select('user_serial, client_uuid')
    .eq('user_serial', user_serial)
    .single();

  if (!scheme) {
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
  return new Response(JSON.stringify({ data: scheme, message: null }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
