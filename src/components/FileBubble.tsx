import { File, Image, Video, Music } from 'lucide-react';

interface FileBubbleProps {
  name: string;
  size: string;
  mimeType: string;
  thumbnailLink?: string;
  webContentLink?: string;
  align?: 'left' | 'right';
  onActionClick?: () => void;
  actionText?: string;
}

export default function FileBubble({
  name,
  size,
  mimeType,
  thumbnailLink,
  webContentLink: _webContentLink,
  align = 'left',
  onActionClick,
  actionText
}: FileBubbleProps) {
  
  const getIcon = () => {
    if (mimeType?.includes('image')) return <Image className="w-5 h-5" />;
    if (mimeType?.includes('video')) return <Video className="w-5 h-5" />;
    if (mimeType?.includes('audio')) return <Music className="w-5 h-5" />;
    return <File className="w-5 h-5" />;
  };

  const isLeft = align === 'left';

  return (
    <div className={`flex w-full mb-4 ${isLeft ? 'justify-start' : 'justify-end'}`}>
      <div 
        className={`max-w-[85%] rounded-[20px] p-2.5 shadow-[0_4px_20px_rgba(0,0,0,0.15)] backdrop-blur-md ${
          isLeft 
            ? 'bg-white/10 text-white rounded-bl-[4px] border border-white/20' 
            : 'bg-indigo-500/80 text-white rounded-br-[4px] border border-indigo-300/30'
        }`}
      >
        {thumbnailLink ? (
          <div className="relative w-64 h-48 mb-2 rounded-[14px] overflow-hidden bg-black/40 shadow-inner">
            <img src={thumbnailLink} alt={name} className="w-full h-full object-cover" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent flex items-end p-3">
              <p className="text-white text-xs font-semibold truncate drop-shadow-md">{name}</p>
            </div>
          </div>
        ) : (
          <div className={`flex items-center gap-3 p-3 rounded-[14px] mb-2 border ${isLeft ? 'bg-black/20 border-white/5' : 'bg-black/10 border-indigo-300/20'}`}>
            <div className={`p-2.5 rounded-[10px] shadow-inner ${isLeft ? 'bg-white/10 text-white' : 'bg-white/20 text-white'}`}>
              {getIcon()}
            </div>
            <div className="flex-1 min-w-0 pr-2">
              <p className="text-sm font-bold truncate tracking-tight text-white drop-shadow-sm">{name}</p>
              <p className={`text-xs mt-0.5 font-medium ${isLeft ? 'text-white/60' : 'text-indigo-100/80'}`}>
                {size !== '0' ? `${(parseInt(size) / 1024 / 1024).toFixed(1)} MB` : 'File'}
              </p>
            </div>
          </div>
        )}
        
        {/* Actions */}
        {actionText && (
          <button 
            onClick={onActionClick}
            className={`w-full mt-2 py-2.5 px-4 rounded-[12px] text-sm font-bold shadow-sm ${
              isLeft ? 'bg-white/20 hover:bg-white/30 text-white' : 'bg-white/20 hover:bg-white/30 text-white'
            }`}
          >
            {actionText}
          </button>
        )}
      </div>
    </div>
  );
}
