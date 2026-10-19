import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, getDriveAccessToken } from "../_shared/token-refresh.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );
    
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    
    const user_id = user?.id;
    if (!user_id || authError) {
      return new Response("Unauthorized", {
        status: 401,
        headers: corsHeaders,
      });
    }

    const { name, parent_folder_id } = await req.json();

    if (!name) {
      return new Response(JSON.stringify({ error: "Space name is required" }), { 
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }
    
    if (!parent_folder_id) {
       return new Response(JSON.stringify({ error: "Parent folder ID (MemInbox) is required" }), { 
         status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } 
       });
    }

    // 1. Get Drive token
    const accessToken = await getDriveAccessToken(user_id);

    // 2. Create Drive Folder
    const folderMetadata = {
      name,
      mimeType: "application/vnd.google-apps.folder",
      parents: [parent_folder_id],
    };

    const driveRes = await fetch("https://www.googleapis.com/drive/v3/files", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(folderMetadata),
    });

    if (!driveRes.ok) {
      const errorText = await driveRes.text();
      return new Response(JSON.stringify({ error: "Failed to create folder in Drive", details: errorText }), { 
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }

    const driveFolderData = await driveRes.json();

    // 3. Insert into Supabase DB
    const { data: insertedSpace, error: spaceInsertError } = await supabaseClient
      .from("spaces")
      .insert({
        user_id,
        name,
        drive_folder_id: driveFolderData.id,
      })
      .select()
      .single();

    if (spaceInsertError) {
       return new Response(JSON.stringify({ error: "Failed to save space to DB", details: spaceInsertError }), { 
         status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } 
       });
    }

    return new Response(JSON.stringify({ success: true, space: insertedSpace }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e: any) {
    return new Response(JSON.stringify({ error: "Internal Server Error", details: e.message }), { 
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });
  }
});
