import { useState, useEffect } from 'react';
import { ArrowLeft, Loader2, Folder as FolderIcon, Send } from 'lucide-react';
import { Link, useParams } from 'react-router-dom';
import FileBubble from '../components/FileBubble';
import { supabase } from '../lib/supabase';
import type { Session } from '@supabase/supabase-js';

export default function SpaceDetail({ session: _session }: { session: Session }) {
  const { id } = useParams();
  const [folders, setFolders] = useState<any[]>([]);
  const [files, setFiles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [inputText, setInputText] = useState('');
  const [isSending, setIsSending] = useState(false);

  useEffect(() => {
    if (id) {
      fetchDriveContents();
    }
  }, [id]);

  const fetchDriveContents = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.functions.invoke('fetch-drive', {
        body: { folder_id: id },
      });

      if (error) throw error;
      setFolders(data.folders || []);
      setFiles(data.files || []);
    } catch (error) {
      console.error('Error fetching drive contents:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSendText = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || isSending) return;

    setIsSending(true);
    try {
      const fileName = `Message-${new Date().toISOString().replace(/[:.]/g, '-')}.txt`;
      const file = new File([inputText], fileName, { type: 'text/plain' });
      
      const formData = new FormData();
      formData.append('file', file);
      formData.append('metadata', JSON.stringify({ drive_parent_id: id || 'root' }));

      const { error } = await supabase.functions.invoke('upload-to-drive', {
        body: formData,
      });

      if (error) throw error;
      
      setInputText('');
      fetchDriveContents();
    } catch (error: any) {
      console.error('Error sending text:', error);
      alert('Failed to send text: ' + (error?.message || JSON.stringify(error)));
    } finally {
      setIsSending(false);
    }
  };

  return (
    <div className="flex flex-col h-screen text-white bg-black/20 relative">
      {/* Dark overlay for chat legibility */}
      <div className="absolute inset-0 bg-black/30 z-0 pointer-events-none backdrop-blur-[2px]" />

      {/* Header */}
      <header className="px-4 py-4 flex items-center gap-4 bg-black/40 backdrop-blur-2xl border-b border-white/10 sticky top-0 z-10 shadow-[0_4px_30px_rgba(0,0,0,0.2)]">
        <Link to="/" className="p-2 -ml-2 hover:bg-white/10 rounded-full transition-colors text-white/80 hover:text-white">
          <ArrowLeft size={24} />
        </Link>
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center border border-white/10 shadow-inner">
            <FolderIcon size={20} className="fill-white/40" />
          </div>
          <div>
            <h1 className="font-bold text-lg leading-tight truncate max-w-[200px] drop-shadow-md text-white">Folder View</h1>
            <p className="text-xs text-white/60 font-medium">{files.length} files, {folders.length} folders</p>
          </div>
        </div>
      </header>

      {/* Chat / Files Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6 relative z-10">
        {loading ? (
          <div className="flex justify-center items-center h-full">
            <Loader2 className="animate-spin text-white/70" size={32} />
          </div>
        ) : (
          <>
            {/* Render Sub-folders as nested chats */}
            {folders.length > 0 && (
              <div className="space-y-2 mb-6">
                <h3 className="text-xs font-bold text-white/50 uppercase tracking-widest pl-2 mb-3">Nested Folders</h3>
                {folders.map((folder) => (
                  <Link
                    key={folder.id}
                    to={`/space/${folder.id}`}
                    className="flex items-center gap-4 p-3 bg-black/30 hover:bg-black/50 backdrop-blur-md rounded-[20px] cursor-pointer border border-white/10 shadow-lg group"
                  >
                    <div className="w-12 h-12 bg-white/10 rounded-full flex items-center justify-center shadow-inner">
                      <FolderIcon size={24} className="fill-white/60 opacity-80" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold text-[16px] truncate text-white drop-shadow-sm">{folder.name}</h3>
                      <p className="text-xs text-white/50 truncate font-medium">Tap to open chat</p>
                    </div>
                  </Link>
                ))}
              </div>
            )}

            {/* Render Files as Messages */}
            {files.length > 0 && (
              <div>
                <h3 className="text-xs font-bold text-white/50 uppercase tracking-widest pl-2 mb-3">Files</h3>
                <div className="space-y-4">
                  {files.map((file) => (
                    <div key={file.id} className="flex justify-end group">
                      <FileBubble
                        name={file.name}
                        size={file.size || '0'}
                        mimeType={file.mimeType}
                        thumbnailLink={file.thumbnailLink}
                        webContentLink={file.webContentLink}
                        align="right"
                      />
                    </div>
                  ))}
                </div>
              </div>
            )}

            {folders.length === 0 && files.length === 0 && (
              <div className="text-center py-20 text-white/60">
                <FolderIcon size={48} className="mx-auto mb-4 opacity-30" />
                <p className="font-medium text-white/80">This folder is completely empty.</p>
                <p className="text-sm opacity-70 mt-1">Files created here will appear as messages.</p>
              </div>
            )}
          </>
        )}
      </div>

      {/* Chat Input Footer */}
      <div className="p-4 bg-black/40 backdrop-blur-2xl border-t border-white/10 relative z-10 shadow-[0_-4px_30px_rgba(0,0,0,0.2)]">
        <form onSubmit={handleSendText} className="relative flex items-center">
          <input
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            placeholder="Message (saves as .txt)..."
            className="w-full bg-white/10 border border-white/20 rounded-[24px] py-3 pl-5 pr-12 text-white placeholder:text-white/50 focus:outline-none focus:border-white/40 focus:bg-white/15 focus:ring-1 focus:ring-white/40 transition-all shadow-inner"
            disabled={isSending}
          />
          <button
            type="submit"
            disabled={!inputText.trim() || isSending}
            className="absolute right-2 top-1/2 -translate-y-1/2 p-2 bg-blue-500 hover:bg-blue-600 disabled:bg-white/10 disabled:text-white/30 text-white rounded-full transition-colors flex items-center justify-center shadow-lg disabled:shadow-none"
          >
            {isSending ? <Loader2 size={18} className="animate-spin" /> : <Send size={18} className="ml-[-2px] mt-[1px]" />}
          </button>
        </form>
      </div>
    </div>
  );
}
