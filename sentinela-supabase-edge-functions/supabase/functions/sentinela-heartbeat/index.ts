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
    const { client, machine_id, fsm_data, pinpad_authenticated, device_battery_level, device_battery_state, bluetooth_rssi } = await req.json();

    // Check if client_id is valid and get the schema from the 'users' table in the public schema
    const { data: client_data, error: clientError } = await supabase.schema('public').from('clients').select('client_schema').eq('id', client).limit(1).single();
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

    // Check if the machine exists in the 'machines' table
    const { data: machine, error: fetchError } = await supabase
        .schema(client_data.client_schema)
        .from('machines')
        .select('id, remote_command_queue, blocked')
        .eq('id', machine_id)
        .limit(1)
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

    // Update Finite State Machine data and others info in the 'machines' table
    const { error: updateError } = await supabase
        .schema(client_data.client_schema)
        .from('machines')
        .update({
            finite_state_machine_monitoring: fsm_data,
            pinpad_authenticated: pinpad_authenticated,
            pos_device_battery_level: device_battery_level ?? null,
            pos_device_battery_state: device_battery_state ?? null,
            interface_bluetooth_rssi_level: bluetooth_rssi ?? null,
        })
        .eq('id', machine_id);

    if (updateError) {
        return new Response(JSON.stringify({ message: 'Falha ao registrar, Tente novamente' }), { status: 500, headers: { 'Content-Type': 'application/json' } });
    }

    // Now we can return some data to the client, like commands, configs, etc.
    // check if have commands to execute
    var heartbeat = {};
    if (Array.isArray(machine.remote_command_queue) && machine.remote_command_queue.length === 0) {
        heartbeat = {
            success: true,
            commands: [],
            is_blocked: machine.blocked,
        };
    } else {
        heartbeat = {
            success: true,
            commands: machine.remote_command_queue,
            is_blocked: machine.blocked,
        };

        // Clean up the command queue to prevent it from repeating
        const { error: cleanupError } = await supabase
            .schema(client_data.client_schema)
            .from('machines')
            .update({
                remote_command_queue: [],
            })
            .eq('id', machine_id);

        if (cleanupError) {
            return new Response(JSON.stringify({ message: 'Falha ao limpar a fila de comandos' }), { status: 500, headers: { 'Content-Type': 'application/json' } });
        }
    }

    // Return the heartbeat response
    return new Response(JSON.stringify(heartbeat), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
    });
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/sentinela-heartbeat' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
