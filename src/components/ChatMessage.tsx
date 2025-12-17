import React from 'react';
import { Message, MessageType } from '../types';
import { Bot, User, Cpu, AlertTriangle, Link, Video, Sparkles } from 'lucide-react';

interface ChatMessageProps {
  message: Message;
  isLatest?: boolean;
}

const ChatMessage: React.FC<ChatMessageProps> = ({ message, isLatest }) => {
  const isUser = message.role === 'user' || message.sender === 'user';
  const isSystem = message.role === 'system' || message.sender === 'system';
  
  return (
    <div className={`flex gap-4 ${isUser ? 'flex-row-reverse' : ''} animate-in fade-in slide-in-from-bottom-2`}>
      <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${
        isUser ? 'bg-indigo-600 text-white' : 
        isSystem ? 'bg-red-900/50 text-red-400' :
        'bg-slate-800 text-indigo-400'
      }`}>
        {isUser ? <User size={18} /> : isSystem ? <AlertTriangle size={18} /> : <Bot size={18} />}
      </div>
      
      <div className={`flex flex-col max-w-[80%] ${isUser ? 'items-end' : 'items-start'}`}>
        <div className="flex items-center gap-2 mb-1">
          <span className="text-xs font-bold text-slate-300">
            {message.agentName || (isUser ? 'You' : 'Nexus')}
          </span>
          <span className="text-[10px] text-slate-500">
            {new Date(message.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </span>
        </div>
        
        <div className={`px-4 py-3 rounded-2xl text-sm leading-relaxed whitespace-pre-wrap ${
          isUser 
            ? 'bg-indigo-600 text-white rounded-tr-none' 
            : isSystem
            ? 'bg-red-900/20 border border-red-900/50 text-red-200 rounded-tl-none'
            : 'bg-slate-900 border border-slate-800 text-slate-300 rounded-tl-none'
        }`}>
          {message.content?.text || message.text}
          
          {message.image && (
            <img 
              src={message.image} 
              alt="Generated" 
              className="mt-3 rounded-lg max-w-full border border-slate-700 shadow-xl" 
            />
          )}

          {(message.video || message.type === MessageType.VIDEO) && message.video && (
             <div className="mt-4 mb-2 relative rounded-xl overflow-hidden border border-cyan-500/50 shadow-[0_0_25px_rgba(6,182,212,0.2)] bg-black/80 backdrop-blur-sm group">
                 {/* Holographic Header */}
                 <div className="absolute top-0 left-0 right-0 h-8 bg-gradient-to-b from-cyan-900/50 to-transparent z-10 flex items-center px-3 border-b border-cyan-500/20">
                    <div className="flex items-center gap-2">
                        <Video size={12} className="text-cyan-400" />
                        <span className="text-[10px] font-mono text-cyan-300 tracking-widest uppercase">Veo Holographic Projection</span>
                    </div>
                    <div className="ml-auto flex gap-1">
                         <span className="w-1 h-1 bg-cyan-400 rounded-full animate-pulse"></span>
                         <span className="w-1 h-1 bg-cyan-400 rounded-full animate-pulse delay-75"></span>
                         <span className="w-1 h-1 bg-cyan-400 rounded-full animate-pulse delay-150"></span>
                    </div>
                 </div>
                 
                 {/* Video Player */}
                 <video 
                    src={message.video} 
                    controls 
                    autoPlay
                    loop
                    muted
                    className="w-full max-h-[400px] object-contain relative z-0 mt-8 mb-2" 
                    poster={message.image} 
                 />

                 {/* Holographic Footer */}
                 <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-cyan-500/50 to-transparent opacity-50"></div>
             </div>
          )}

          {/* Sources / Citations */}
          {message.metadata?.sources && message.metadata.sources.length > 0 && (
             <div className="mt-4 pt-3 border-t border-slate-700/50">
                 <div className="text-[10px] font-bold text-slate-400 mb-2 flex items-center gap-1">
                    <Link size={10} /> CITATIONS
                 </div>
                 <div className="flex flex-wrap gap-2">
                     {message.metadata.sources.map((src, i) => {
                         let hostname = src;
                         try { hostname = new URL(src).hostname.replace('www.', ''); } catch (e) {}
                         
                         return (
                            <a 
                                key={i} 
                                href={src} 
                                target="_blank" 
                                rel="noreferrer" 
                                className="flex items-center gap-1.5 text-[10px] bg-slate-800 hover:bg-indigo-900/30 text-indigo-300 px-2 py-1.5 rounded border border-slate-700 hover:border-indigo-500/30 transition-all max-w-[200px] truncate"
                            >
                                <span className="truncate">{hostname}</span>
                            </a>
                         );
                     })}
                 </div>
             </div>
          )}
        </div>

        {message.context && !isUser && (
          <div className="mt-1 flex items-center gap-2 text-[10px] text-slate-500">
            <Cpu size={10} />
            <span>{message.context.model}</span>
            {message.metadata?.processingTime && (
                <span>• {message.metadata.processingTime}ms</span>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ChatMessage;
