import { createClient } from "npm:@supabase/supabase-js@2";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
);

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/**
 * Fetches Drive tokens for the user and refreshes if expired.
 * Uses the service-role client to bypass RLS on drive_tokens.
 * Returns the current (possibly refreshed) access token.
 */
export async function getDriveAccessToken(userId: string): Promise<string> {
  const { data: tokenData, error: tokenError } = await supabaseAdmin
    .from("drive_tokens")
    .select("*")
    .eq("user_id", userId)
    .single();

  if (!tokenData || tokenError) {
    throw new Error("Google Drive not connected");
  }

  let accessToken: string = tokenData.access_token;

  if (new Date(tokenData.expiry) < new Date()) {
    const refreshRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: Deno.env.get("GOOGLE_CLIENT_ID") || "",
        client_secret: Deno.env.get("GOOGLE_CLIENT_SECRET") || "",
        refresh_token: tokenData.refresh_token,
        grant_type: "refresh_token",
      }),
    });

    if (!refreshRes.ok) {
      throw new Error("Failed to refresh Google token");
    }

    const refreshData = await refreshRes.json();
    accessToken = refreshData.access_token;

    await supabaseAdmin
      .from("drive_tokens")
      .update({
        access_token: accessToken,
        expiry: new Date(Date.now() + refreshData.expires_in * 1000).toISOString(),
      })
      .eq("user_id", userId);
  }

  return accessToken;
}
