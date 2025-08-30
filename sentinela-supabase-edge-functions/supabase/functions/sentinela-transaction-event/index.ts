// @ts-nocheck
// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2'; // Adjust the version as needed
const supabaseUrl = Deno.env.get('SUPABASE_URL'); // Set your Supabase URL in environment variables
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY'); // Set your Supabase anon key in environment variables
const supabase = createClient(supabaseUrl, supabaseKey);
Deno.serve(async (req) => {
    const {
        client,
        machine,
        price,
        product,
        type,
        method,
        product_delivered_status,
        transaction_status_description,
        transaction_status,
        receipt,
        event_id,
        interface_epoch_timestamp,
        timestamp,
        sale_status,
    } = await req.json();
    // Check if the request is valid
    if (
        client == null ||
        machine == null ||
        price == null ||
        product == null ||
        type == null ||
        method == null ||
        product_delivered_status == null ||
        transaction_status_description == null ||
        transaction_status == null ||
        receipt == null ||
        event_id == null ||
        interface_epoch_timestamp == null ||
        timestamp == null ||
        sale_status == null
    ) {
        return new Response(
            JSON.stringify({
                message: 'Dados inválidos, Tente novamente',
            }),
            {
                status: 400,
                headers: {
                    'Content-Type': 'application/json',
                },
            },
        );
    }
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
    // Check if the machine exists in the 'machines' table in the client's schema
    const { data: machine_data, error: fetchError } = await supabase.schema(client_data.client_schema).from('machines').select('id').eq('id', machine).limit(1).single();
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

    // BULLETPROOF DUPLICATE CHECK: Verify if transaction already exists
    // Check with 5 key fields: machine_id + event_id + price + type + method
    console.log(`Checking for duplicate transaction: machine=${machine}, event_id=${event_id}, price=${price}, type=${type}, method=${method}`);

    const { data: existingTransaction, error: duplicateCheckError } = await supabase
        .schema(client_data.client_schema)
        .from('sale_transactions')
        .select('transaction_id, timestamp, price, type, method')
        .eq('machine_id', machine)
        .eq('transaction_id', event_id)
        .eq('price', price)
        .eq('type', type)
        .eq('method', method)
        .limit(1)
        .single();

    if (duplicateCheckError && duplicateCheckError.code !== 'PGRST116') {
        // PGRST116 = no rows found, which is what we want (no duplicate)
        console.error('Error checking for duplicates:', duplicateCheckError);
        return new Response(
            JSON.stringify({
                message: 'Erro ao verificar duplicatas, Tente novamente',
                error: duplicateCheckError.message,
            }),
            {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                },
            },
        );
    }

    if (existingTransaction) {
        console.log(`DUPLICATE TRANSACTION BLOCKED!`);
        console.log(`Machine: ${machine}, Event ID: ${event_id}`);
        console.log(
            `Existing: timestamp=${existingTransaction.timestamp}, price=${existingTransaction.price}, type=${existingTransaction.type}, method=${existingTransaction.method}`,
        );
        console.log(`Attempted: timestamp=${timestamp}, price=${price}, type=${type}, method=${method}`);

        return new Response(
            JSON.stringify({
                success: true, // Return success since transaction was already processed
                message: 'Transação já foi processada anteriormente - removendo da fila local',
                duplicate_detected: true,
                already_saved: true, // Flag to indicate server already has this transaction
                existing_transaction: {
                    event_id: existingTransaction.transaction_id,
                    timestamp: existingTransaction.timestamp,
                    price: existingTransaction.price,
                    type: existingTransaction.type,
                    method: existingTransaction.method,
                },
            }),
            {
                status: 200, // Return 200 (success) instead of 409 (conflict)
                headers: {
                    'Content-Type': 'application/json',
                },
            },
        );
    }

    console.log(`No duplicate found, proceeding with transaction: event_id=${event_id}`);

    // insert transaction event on sale_transactions
    const { error: insertError } = await supabase.schema(client_data.client_schema).from('sale_transactions').insert({
        machine_id: machine_data.id,
        price: price,
        product: product,
        type: type,
        method: method,
        product_delivered_status: product_delivered_status,
        transaction_status_description: transaction_status_description,
        transaction_status: transaction_status,
        receipt: receipt,
        transaction_id: event_id,
        interface_epoch_timestamp: interface_epoch_timestamp,
        timestamp: timestamp,
        sale_status: sale_status,
    });
    if (insertError) {
        return new Response(
            JSON.stringify({
                message: 'Falha ao registrar, Tente novamente',
                error: insertError.message,
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
        message: 'Transaction event registered successfully',
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/sentinela-transaction-event' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
