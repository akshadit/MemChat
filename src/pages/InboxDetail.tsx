import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Folder as FolderIcon, Inbox } from 'lucide-react';
import { Drawer } from 'vaul';
import FileBubble from '../components/FileBubble';
import { supabase } from '../lib/supabase';
import type { Session } from '@supabase/supabase-js';

export default function InboxDetail({ session: _session }: { session: Session }) {
  const [selectedFileId, setSelectedFileId] = useState<string | null>(null);
  const [inboxFiles, setInboxFiles] = useState<any[]>([]);
  const [spaces, setSpaces] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();

    const channel = supabase
      .channel('inbox_changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'inbox_items' }, fetchData)
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchData = async () => {
    const { data: inboxData } = await supabase
      .from('inbox_items')
      .select('*, files(*)')
      .eq('is_sorted', false)
      .order('added_at', { ascending: false });

    if (inboxData) {
      setInboxFiles(inboxData.map(item => item.files));
    }

    const { data: spacesData } = await supabase
      .from('spaces')
      .select('*')
      .order('position', { ascending: true });
      
    if (spacesData) setSpaces(spacesData);
    setLoading(false);
  };

  const handleMove = async (spaceId: string) => {
    if (!selectedFileId) return;
    
    // Call Edge Function
    const { error } = await supabase.functions.invoke('move-to-space', {
      body: { file_id: selectedFileId, target_space_id: spaceId }
    });

    if (error) {
      alert("Failed to move: " + error.message);
    } else {
      setSelectedFileId(null);
      // fetchData() is called by realtime trigger, but we can do optimistic update here too.
    }
  };

  return (
    <div className="flex flex-col h-screen bg-black/20 text-[var(--text-primary)]">
      {/* Header */}
      <div className="flex items-center justify-between p-4 bg-black/40 backdrop-blur-2xl sticky top-0 z-10 border-b border-white/10 shadow-[0_4px_30px_rgba(0,0,0,0.2)]">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-white drop-shadow-md">Inbox</h1>
          <p className="text-xs text-white/60 font-medium">{inboxFiles.length} items to sort</p>
        </div>
      </div>

      {/* Chat Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 relative z-10">
        {loading ? (
          <p className="text-center text-white/60 my-4">Loading...</p>
        ) : inboxFiles.length === 0 ? (
          <p className="text-center text-white/50 my-4 font-medium">No new files in inbox.</p>
        ) : (
          inboxFiles.map((file) => (
            <Drawer.Root 
              key={file.id} 
              open={selectedFileId === file.id} 
              onOpenChange={(open) => !open && setSelectedFileId(null)}
            >
              <Drawer.Trigger asChild>
                <div onClick={() => setSelectedFileId(file.id)}>
                  <FileBubble 
                    name={file.original_name}
                    size={(file.size_bytes / 1024 / 1024).toFixed(1) + ' MB'}
                    mimeType={file.mime_type}
                    thumbnailLink={file.thumbnail_link}
                    align="left"
                    actionText="Move to Space"
                    onActionClick={() => setSelectedFileId(file.id)}
                  />
                </div>
              </Drawer.Trigger>
              <Drawer.Portal>
                <Drawer.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40" />
                <Drawer.Content className="bg-black/60 backdrop-blur-2xl flex flex-col rounded-t-[32px] mt-24 fixed bottom-0 left-0 right-0 z-50 p-6 pb-8 border-t border-white/10 shadow-[0_-10px_40px_rgba(0,0,0,0.3)]">
                  <div className="mx-auto w-12 h-1.5 flex-shrink-0 rounded-full bg-white/20 mb-6" />
                  <Drawer.Title className="font-bold text-xl mb-4 text-center text-white drop-shadow-md">Select Space</Drawer.Title>
                  <div className="space-y-2 max-h-64 overflow-y-auto hide-scrollbar">
                    {spaces.map((space) => (
                      <button 
                        key={space.id}
                        onClick={() => handleMove(space.id)}
                        className="w-full flex items-center gap-4 p-4 rounded-[20px] bg-white/5 hover:bg-white/10 transition-colors border border-white/5"
                      >
                        <div className="w-12 h-12 bg-white/10 rounded-full flex items-center justify-center text-lg font-bold text-white shadow-inner">
                          {space.name.charAt(0)}
                        </div>
                        <span className="font-medium text-lg text-white">{space.name}</span>
                      </button>
                    ))}
                    <button className="w-full flex items-center justify-center gap-2 p-4 rounded-[20px] border border-dashed border-white/30 text-white/70 mt-4 font-semibold hover:bg-white/10 hover:text-white transition-all">
                      + Create New Space
                    </button>
                  </div>
                </Drawer.Content>
              </Drawer.Portal>
            </Drawer.Root>
          ))
        )}
      </div>

      {/* Bottom Navigation */}
      <nav className="flex justify-around items-center py-3 bg-black/50 backdrop-blur-2xl border-t border-white/10 pb-safe shadow-[0_-10px_30px_rgba(0,0,0,0.3)] relative z-20">
        <Link to="/" className="flex flex-col items-center gap-1 text-white/50 hover:text-white/80 transition-colors">
          <FolderIcon size={24} />
          <span className="text-[11px] font-medium tracking-wide">Chats</span>
        </Link>
        <button className="flex flex-col items-center gap-1 text-white">
          <Inbox size={24} className="fill-white/30" />
          <span className="text-[11px] font-semibold tracking-wide">Inbox</span>
        </button>
      </nav>
    </div>
  );
}
