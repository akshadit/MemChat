import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Inbox, Folder as FolderIcon, Search, LogOut, Loader2, MoreVertical, Plus } from 'lucide-react';
import { supabase } from '../lib/supabase';
import type { Session } from '@supabase/supabase-js';

interface Folder {
  id: string;
  name: string;
  modifiedTime: string;
}

export default function SpacesList({ session: _session }: { session: Session }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [folders, setFolders] = useState<Folder[]>([]);
  const [loading, setLoading] = useState(true);
  const [showMenu, setShowMenu] = useState(false);
  const [showNewChatModal, setShowNewChatModal] = useState(false);
  const [newChatName, setNewChatName] = useState('');
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    fetchDriveRoot();
  }, []);

  const fetchDriveRoot = async () => {
    try {
      const { data, error } = await supabase.functions.invoke('fetch-drive', {
        body: {}, // defaults to root folder
      });

      if (error) throw error;
      setFolders(data.folders || []);
    } catch (error: any) {
      console.error('Error fetching drive root:', error);
      alert('Error fetching drive root: ' + (error.message || JSON.stringify(error)));
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
  };

  const handleCreateChat = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newChatName.trim()) return;
    setCreating(true);
    try {
      const { data, error } = await supabase.functions.invoke('create-space', {
        body: {
          name: newChatName,
          parent_folder_id: 'root'
        }
      });

      if (error) {
        throw error;
      }
      
      if (data?.error) {
        throw new Error(data.error);
      }
      
      setNewChatName('');
      setShowNewChatModal(false);
      fetchDriveRoot(); // refresh the folder list
    } catch (err: any) {
      console.error(err);
      alert('Error creating chat: ' + (err.message || JSON.stringify(err)));
    } finally {
      setCreating(false);
    }
  };

  const filteredFolders = folders.filter((f) => f.name.toLowerCase().includes(searchQuery.toLowerCase()));

  return (
    <div className="flex flex-col h-screen text-[var(--text-primary)] bg-black/20">
      <header className="px-4 py-4 flex justify-between items-center bg-black/40 backdrop-blur-xl border-b border-white/10 sticky top-0 z-50 shadow-[0_4px_30px_rgba(0,0,0,0.1)]">
        <h1 className="text-xl font-bold tracking-tight text-white drop-shadow-md">Drive Chats</h1>
        
        <div className="relative">
          <button 
            onClick={() => setShowMenu(!showMenu)} 
            className="p-2 hover:bg-white/10 rounded-full text-white/80 transition-colors"
          >
            <MoreVertical size={20} />
          </button>
          
          {showMenu && (
            <div className="absolute right-0 mt-2 w-48 bg-[#1A1D24]/95 backdrop-blur-xl rounded-2xl shadow-lg border border-white/10 overflow-hidden z-50">
              <div className="p-2">
                <button className="w-full text-left px-4 py-3 text-sm text-white/80 hover:bg-white/10 rounded-xl transition-colors">
                  Settings
                </button>
                <button 
                  onClick={handleSignOut}
                  className="w-full flex items-center gap-2 px-4 py-3 text-sm text-rose-400 hover:bg-rose-500/10 rounded-xl transition-colors"
                >
                  <LogOut size={16} />
                  Sign Out
                </button>
              </div>
            </div>
          )}
        </div>
      </header>

      <div className="p-4 bg-transparent sticky top-[61px] z-10">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-white/60" size={18} />
          <input
            type="text"
            placeholder="Search folders..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-black/30 backdrop-blur-md border border-white/10 rounded-2xl py-3 pl-10 pr-4 focus:outline-none focus:border-white/30 focus:ring-1 focus:ring-white/20 transition-all placeholder:text-white/40 text-white shadow-inner"
          />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto pb-safe">
        {loading ? (
          <div className="flex justify-center items-center h-32">
            <Loader2 className="animate-spin text-white/70" size={24} />
          </div>
        ) : (
          <div className="space-y-2 px-3 pb-6">
            {filteredFolders.map((folder) => {
              // Generate a consistent, vibrant color based on the folder name
              const colors = [
                { bg: 'bg-blue-500/20', text: 'text-blue-300' },
                { bg: 'bg-emerald-500/20', text: 'text-emerald-300' },
                { bg: 'bg-purple-500/20', text: 'text-purple-300' },
                { bg: 'bg-rose-500/20', text: 'text-rose-300' },
                { bg: 'bg-amber-500/20', text: 'text-amber-300' },
                { bg: 'bg-cyan-500/20', text: 'text-cyan-300' },
                { bg: 'bg-pink-500/20', text: 'text-pink-300' },
              ];
              const colorIndex = folder.name.split('').reduce((acc: number, char: string) => acc + char.charCodeAt(0), 0) % colors.length;
              const color = colors[colorIndex];

              return (
                <Link
                  key={folder.id}
                  to={`/space/${folder.id}`}
                  className="flex items-center gap-4 p-3 bg-black/20 hover:bg-black/40 backdrop-blur-md rounded-3xl border border-white/5 cursor-pointer group shadow-[0_4px_20px_rgba(0,0,0,0.15)]"
                >
                  <div className={`w-13 h-13 min-w-[52px] min-h-[52px] ${color.bg} ${color.text} rounded-full flex items-center justify-center shadow-inner border border-white/10`}>
                    <FolderIcon size={24} className="fill-current opacity-60" />
                  </div>
                  <div className="flex-1 pb-1 min-w-0">
                    <div className="flex justify-between items-baseline mb-0.5">
                      <h3 className="font-semibold text-[17px] text-white truncate pr-2 tracking-tight drop-shadow-sm">{folder.name}</h3>
                      <span className="text-xs text-white/60 shrink-0 font-medium">
                        {new Date(folder.modifiedTime).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
                      </span>
                    </div>
                    <p className="text-[14px] text-white/50 truncate font-medium">
                      Shared Folder
                    </p>
                  </div>
                </Link>
              );
            })}
            {filteredFolders.length === 0 && (
              <div className="text-center py-16 text-white/60">
                <FolderIcon size={48} className="mx-auto mb-4 opacity-30" />
                <p className="font-medium text-white/80">No folders found in root</p>
                <p className="text-sm opacity-70 mt-1">Try creating one in Google Drive</p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Floating Action Button for New Chat */}
      <button 
        onClick={() => setShowNewChatModal(true)}
        className="absolute bottom-20 right-6 w-14 h-14 bg-indigo-500 hover:bg-indigo-400 rounded-full flex items-center justify-center shadow-[0_8px_30px_rgba(99,102,241,0.5)] transition-transform hover:scale-105 active:scale-95 z-30 border border-indigo-300/30"
      >
        <Plus size={28} className="text-white drop-shadow-md" />
      </button>

      {/* New Chat Modal */}
      {showNewChatModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-[#1A1D24]/95 backdrop-blur-xl w-full max-w-sm rounded-3xl p-6 shadow-[0_10px_40px_rgba(0,0,0,0.5)] border border-white/10">
            <h2 className="text-xl font-bold text-white mb-4">New Chat</h2>
            <form onSubmit={handleCreateChat}>
              <input
                type="text"
                autoFocus
                placeholder="Chat Name (e.g. Project Idea)"
                value={newChatName}
                onChange={(e) => setNewChatName(e.target.value)}
                className="w-full bg-black/40 border border-white/10 rounded-2xl py-3 px-4 text-white placeholder-white/40 focus:outline-none focus:border-indigo-500/50 focus:ring-1 focus:ring-indigo-500/50 mb-6 shadow-inner"
              />
              <div className="flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowNewChatModal(false)}
                  className="px-5 py-2.5 rounded-xl text-white/70 hover:bg-white/10 font-medium transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={creating || !newChatName.trim()}
                  className="px-5 py-2.5 bg-indigo-500 hover:bg-indigo-400 disabled:bg-indigo-500/50 disabled:cursor-not-allowed rounded-xl text-white font-bold shadow-md transition-colors flex items-center gap-2"
                >
                  {creating && <Loader2 size={16} className="animate-spin" />}
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <nav className="flex justify-around items-center py-3 bg-black/50 backdrop-blur-2xl border-t border-white/10 pb-safe shadow-[0_-10px_30px_rgba(0,0,0,0.3)] relative z-20">
        <button className="flex flex-col items-center gap-1 text-white">
          <FolderIcon size={24} className="fill-white/30" />
          <span className="text-[11px] font-semibold tracking-wide">Chats</span>
        </button>
        <Link to="/inbox" className="flex flex-col items-center gap-1 text-white/50 hover:text-white/80 transition-colors">
          <Inbox size={24} />
          <span className="text-[11px] font-medium tracking-wide">Inbox</span>
        </Link>
      </nav>
    </div>
  );
}
