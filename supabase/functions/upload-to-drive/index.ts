import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, getDriveAccessToken } from "../_shared/token-refresh.ts";

const GOOGLE_UPLOAD_URL =
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart";

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

    const formData = await req.formData();
      const file = formData.get("file") as File;
      const metadataStr = formData.get("metadata") as string;

      if (!file) {
        return new Response(
          JSON.stringify({ error: "No file provided" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const metadata = metadataStr ? JSON.parse(metadataStr) : {};
      const driveParentId = metadata.drive_parent_id;

      if (!driveParentId) {
        return new Response(
          JSON.stringify({ error: "No drive_parent_id provided" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const today = new Date().toISOString().split("T")[0];
      const { data: stats } = await supabaseClient
        .from("user_usage_stats")
        .select("*")
        .eq("user_id", user_id)
        .eq("date", today)
        .single();

      const currentUploadCount = stats?.upload_count || 0;
      const currentBytes = stats?.bytes_uploaded || 0;

      if (
        currentUploadCount >= 50 ||
        currentBytes + file.size > 500 * 1024 * 1024
      ) {
        return new Response(
          JSON.stringify({ error: "Rate limit exceeded (50 uploads or 500MB/day)" }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const accessToken = await getDriveAccessToken(user_id);

      const multipartBody = new FormData();
      multipartBody.append(
        "metadata",
        new Blob(
          [JSON.stringify({ name: file.name, parents: [driveParentId] })],
          { type: "application/json" }
        )
      );
      multipartBody.append("file", file);

      const driveRes = await fetch(GOOGLE_UPLOAD_URL, {
        method: "POST",
        headers: { Authorization: `Bearer ${accessToken}` },
        body: multipartBody,
      });

      if (!driveRes.ok) {
        const errorText = await driveRes.text();
        return new Response(
          JSON.stringify({ error: "Drive upload failed", details: errorText }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const driveFileData = await driveRes.json();

      const fileDetailsRes = await fetch(
        `https://www.googleapis.com/drive/v3/files/${driveFileData.id}?fields=id,thumbnailLink,webContentLink,mimeType,size`,
        { headers: { Authorization: `Bearer ${accessToken}` } }
      );
      const fileDetails = await fileDetailsRes.json();

      await supabaseClient.from("user_usage_stats").upsert({
        user_id,
        date: today,
        upload_count: currentUploadCount + 1,
        bytes_uploaded: currentBytes + file.size,
      });

      const { data: insertedFile, error: fileInsertError } = await supabaseClient
        .from("files")
        .insert({
          user_id,
          drive_file_id: fileDetails.id,
          drive_parent_id: driveParentId,
          mime_type: fileDetails.mimeType || file.type,
          original_name: file.name,
          size_bytes: parseInt(fileDetails.size || file.size.toString()),
          thumbnail_link: fileDetails.thumbnailLink,
          web_content_link: fileDetails.webContentLink,
        })
        .select()
        .single();

      if (fileInsertError) {
        return new Response(
          JSON.stringify({ error: "Failed to save file metadata to DB", details: fileInsertError }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { error: inboxInsertError } = await supabaseClient
        .from("inbox_items")
        .insert({ file_id: insertedFile.id, user_id, is_sorted: false });

      if (inboxInsertError) {
        return new Response(
          JSON.stringify({ error: "Failed to add to inbox", details: inboxInsertError }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(JSON.stringify({ success: true, file: insertedFile }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (e: any) {
      return new Response(
        JSON.stringify({ error: "Internal Server Error", details: e.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
});
