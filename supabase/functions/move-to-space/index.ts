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
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const { file_id, target_space_id } = await req.json();

      if (!file_id || !target_space_id) {
        return new Response(
          JSON.stringify({ error: "file_id and target_space_id are required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { data: fileData } = await supabaseClient
        .from("files")
        .select("id, drive_file_id, drive_parent_id")
        .eq("id", file_id)
        .single();

      if (!fileData) {
        return new Response(
          JSON.stringify({ error: "File not found" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { data: spaceData } = await supabaseClient
        .from("spaces")
        .select("id, drive_folder_id")
        .eq("id", target_space_id)
        .single();

      if (!spaceData) {
        return new Response(
          JSON.stringify({ error: "Target space not found" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const accessToken = await getDriveAccessToken(user_id);

      const driveRes = await fetch(
        `https://www.googleapis.com/drive/v3/files/${fileData.drive_file_id}?addParents=${spaceData.drive_folder_id}&removeParents=${fileData.drive_parent_id}`,
        {
          method: "PATCH",
          headers: { Authorization: `Bearer ${accessToken}` },
        }
      );

      if (!driveRes.ok) {
        const errorText = await driveRes.text();
        return new Response(
          JSON.stringify({ error: "Failed to move file in Drive", details: errorText }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await supabaseClient
        .from("files")
        .update({ space_id: spaceData.id, drive_parent_id: spaceData.drive_folder_id })
        .eq("id", file_id);

      await supabaseClient
        .from("inbox_items")
        .update({ is_sorted: true })
        .eq("file_id", file_id);

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (e: any) {
      return new Response(
        JSON.stringify({ error: "Internal Server Error", details: e.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
});
