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

      let folderId = "root";
      if (req.method === "POST") {
        try {
          const body = await req.json();
          if (body.folder_id) folderId = body.folder_id;
        } catch (_e) {
          // Empty body is fine
        }
      }

      console.log("Before getDriveAccessToken");
      const accessToken = await getDriveAccessToken(user_id);
      console.log("After getDriveAccessToken, token:", !!accessToken);

      let query = `'${folderId}' in parents and trashed = false`;
      if (folderId === "root") {
        query = `('root' in parents or sharedWithMe = true) and trashed = false`;
      }

      const fields =
        "files(id, name, mimeType, size, thumbnailLink, webContentLink, iconLink, modifiedTime)";
      const driveUrl = `https://www.googleapis.com/drive/v3/files?q=${encodeURIComponent(query)}&fields=${encodeURIComponent(fields)}&orderBy=folder,modifiedTime desc`;

      console.log("Before fetch driveUrl:", driveUrl);
      const driveRes = await fetch(driveUrl, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      console.log("After fetch driveUrl, status:", driveRes.status);

      if (!driveRes.ok) {
        const errorText = await driveRes.text();
        return new Response(
          JSON.stringify({ error: "Failed to fetch from Drive", details: errorText }),
          { status: driveRes.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const driveData = await driveRes.json();

      const folders = (driveData.files || []).filter(
        (f: any) => f.mimeType === "application/vnd.google-apps.folder"
      );
      const files = (driveData.files || []).filter(
        (f: any) => f.mimeType !== "application/vnd.google-apps.folder"
      );

      return new Response(JSON.stringify({ folders, files }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (e: any) {
      return new Response(
        JSON.stringify({ error: "Internal Server Error", details: e.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
});
