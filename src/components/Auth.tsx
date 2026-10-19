import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Session } from '@supabase/supabase-js';

export default function Auth({ children }: { children: (session: Session) => React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session }, error }) => {
      if (error) {
        console.error('Auth getSession error:', error);
      }
      setSession(session);
      setLoading(false);
      
      // Save tokens on initial load if we just logged in
      if (session) saveTokensToDB(session);
    }).catch(err => {
      console.error('Auth getSession caught exception:', err);
      setLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      if (session) saveTokensToDB(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  const saveTokensToDB = async (session: Session) => {
    if (!session.provider_token) return;

    // Calculate expiry based on expires_in or fallback to 1 hour
    const expiresIn = session.expires_in || 3600;
    const expiryDate = new Date(Date.now() + expiresIn * 1000).toISOString();

    const updatePayload: any = {
      user_id: session.user.id,
      access_token: session.provider_token,
      expiry: expiryDate,
      scope: 'https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/drive.file'
    };

    if (session.provider_refresh_token) {
      updatePayload.refresh_token = session.provider_refresh_token;
    }

    await supabase.from('drive_tokens').upsert(updatePayload);
  };

  const handleGoogleLogin = async () => {
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          scopes: 'https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/drive.file',
          queryParams: {
            access_type: 'offline',
            prompt: 'consent',
          },
        },
      });
      if (error) throw error;
    } catch (error: any) {
      alert(error.error_description || error.message);
    }
  };

  if (loading) {
    return <div className="flex h-screen items-center justify-center bg-gray-950 text-white">Loading...</div>;
  }

  if (!session) {
    return (
      <div className="flex h-screen items-center justify-center bg-black/20 text-[var(--text-primary)] p-4 relative overflow-hidden backdrop-blur-sm">
        {/* Subtle Background Glow */}
        <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-[var(--accent-primary)]/20 rounded-full blur-[100px] pointer-events-none" />

        <div className="w-full max-w-sm p-8 glass-panel rounded-2xl flex flex-col items-center relative z-10">
          <div className="w-16 h-16 bg-[var(--bg-surface-hover)] rounded-2xl border border-[var(--border-light)] flex items-center justify-center mb-6 shadow-md">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-8 h-8 text-[var(--accent-primary)]">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
            </svg>
          </div>
          
          <h1 className="text-3xl font-bold mb-2 text-center text-white">MemInbox</h1>
          <p className="text-[var(--text-secondary)] text-center text-sm mb-8">
            Your Google Drive, reimagined as a fluid messaging experience.
          </p>
          
          <button 
            onClick={handleGoogleLogin}
            className="w-full bg-[var(--text-primary)] text-[var(--bg-main)] font-semibold py-3.5 rounded-xl hover:bg-white flex items-center justify-center gap-3 shadow-lg"
          >
            <svg viewBox="0 0 24 24" className="w-5 h-5">
              <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
              <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
              <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
              <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
            </svg>
            Continue with Google
          </button>
        </div>
      </div>
    );
  }

  return <>{children(session)}</>;
}
