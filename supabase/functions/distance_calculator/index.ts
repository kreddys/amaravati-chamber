// distance_calculator.ts
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

interface Point {
  x: number; // longitude
  y: number; // latitude
}

interface DistanceCalculationRequest {
  target_lat: number;
  target_lon: number;
}

class AppLogger {
  static debug(message: string, data?: any) {
    console.log(`[DEBUG] ${new Date().toISOString()} - ${message}`, data ? JSON.stringify(data, null, 2) : '');
  }

  static error(message: string, error?: any) {
    console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, error ? JSON.stringify(error, null, 2) : '');
  }
}

serve(async (req) => {
  const requestId = crypto.randomUUID();
  
  try {
    // Verify request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    // Get Supabase connection details from environment
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing required environment variables');
    }

    // Parse request body
    const requestData: DistanceCalculationRequest = await req.json();
    
    if (!requestData.target_lat || !requestData.target_lon) {
      return new Response(
        JSON.stringify({ error: 'Missing target coordinates' }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    AppLogger.debug('Calculating distances for coordinates', {
      requestId,
      targetLat: requestData.target_lat,
      targetLon: requestData.target_lon
    });

    // Execute PostgreSQL query with PostGIS functions
    const query = `
      SELECT 
        id,
        name,
        address,
        phones,
        websites,
        ST_Distance(
          wkb_geometry::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) as distance
      FROM amaravati_places
      WHERE wkb_geometry IS NOT NULL
      ORDER BY distance ASC
    `;

    const response = await fetch(
      `${supabaseUrl}/rest/v1/rpc/calculate_distances`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        },
        body: JSON.stringify({
          target_lon: requestData.target_lon,
          target_lat: requestData.target_lat
        })
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Database query failed: ${errorText}`);
    }

    const results = await response.json();

    return new Response(
      JSON.stringify({
        success: true,
        data: results
      }),
      { 
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    AppLogger.error('Error processing distance calculation', {
      requestId,
      error: {
        message: error.message,
        stack: error.stack
      }
    });

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
});