import React, { useState, useEffect } from 'react';
import { Lock, Fingerprint, ShieldCheck, Key, ExternalLink } from 'lucide-react';

interface LoginProps {
  onLogin: () => void;
}

export const Login: React.FC<LoginProps> = ({ onLogin }) => {
  const [loading, setLoading] = useState(false);
  const [hasApiKey, setHasApiKey] = useState(false);

  useEffect(() => {
    checkApiKey();
  }, []);

  const checkApiKey = async () => {
    const aistudio = (window as any).aistudio;
    if (aistudio && aistudio.hasSelectedApiKey) {
      const selected = await aistudio.hasSelectedApiKey();
      setHasApiKey(selected);
    }
  };

  const handleKeySelection = async () => {
    const aistudio = (window as any).aistudio;
    if (aistudio && aistudio.openSelectKey) {
      await aistudio.openSelectKey();
      setHasApiKey(true);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!hasApiKey) {
      await handleKeySelection();
      return;
    }

    setLoading(true);
    setTimeout(() => {
      onLogin();
    }, 1500);
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center relative overflow-hidden">
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden z-0">
        <div className="absolute -top-[20%] -left-[10%] w-[50%] h-[50%] rounded-full bg-indigo-600/20 blur-[120px]"></div>
        <div className="absolute top-[40%] -right-[10%] w-[40%] h-[60%] rounded-full bg-violet-600/20 blur-[120px]"></div>
      </div>

      <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 p-8 rounded-3xl shadow-2xl w-full max-w-md relative z-10">
        <div className="text-center mb-10">
          <div className="w-20 h-20 bg-gradient-to-tr from-indigo-500 to-violet-600 rounded-2xl mx-auto flex items-center justify-center mb-6 shadow-xl shadow-indigo-500/30">
            <Fingerprint size={40} className="text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">System Access</h1>
          <p className="text-slate-400">GrAtech AI Integrated Backbone</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-2">
            <label className="text-sm font-medium text-slate-300 ml-1">Identity Token</label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <ShieldCheck size={20} className="text-slate-500" />
              </div>
              <input
                type="text"
                placeholder="Admin Identity"
                defaultValue="admin@gratech.sa"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3.5 pl-11 pr-4 focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none transition-all placeholder-slate-500"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-slate-300 ml-1">Secure Key</label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <Lock size={20} className="text-slate-500" />
              </div>
              <input
                type="password"
                placeholder="••••••••••••"
                defaultValue="password123"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3.5 pl-11 pr-4 focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none transition-all placeholder-slate-500"
              />
            </div>
          </div>

          <div className={`p-3 rounded-xl border flex items-center justify-between transition-colors ${hasApiKey ? 'bg-emerald-500/10 border-emerald-500/20' : 'bg-amber-500/10 border-amber-500/20'}`}>
            <div className="flex items-center gap-3">
               <Key size={18} className={hasApiKey ? 'text-emerald-400' : 'text-amber-400'} />
               <div className="text-left">
                  <div className={`text-xs font-bold ${hasApiKey ? 'text-emerald-400' : 'text-amber-400'}`}>
                    {hasApiKey ? 'Neural Link Active' : 'Neural Link Pending'}
                  </div>
                  <div className="text-[10px] text-slate-400">
                    {hasApiKey ? 'Google Cloud Billing Verified' : 'Paid Project Key Required for Veo'}
                  </div>
               </div>
            </div>
            {!hasApiKey && (
                <button 
                  type="button"
                  onClick={handleKeySelection}
                  className="px-3 py-1.5 bg-amber-500 text-black text-[10px] font-bold rounded hover:bg-amber-400 transition-colors"
                >
                  SELECT KEY
                </button>
            )}
          </div>

          <button
            type="submit"
            disabled={loading}
            className={`w-full font-semibold py-4 rounded-xl shadow-lg transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] flex items-center justify-center gap-2 ${
                !hasApiKey 
                ? 'bg-amber-600 hover:bg-amber-500 text-white shadow-amber-600/30'
                : 'bg-indigo-600 hover:bg-indigo-500 text-white shadow-indigo-600/30'
            } ${loading ? 'opacity-80 cursor-wait' : ''}`}
          >
            {loading ? (
              <>
                <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <span>Authenticating...</span>
              </>
            ) : (
              !hasApiKey ? 'Connect & Login' : 'Initiate Session'
            )}
          </button>
        </form>

        <div className="mt-8 text-center space-y-2">
           <a 
             href="https://ai.google.dev/gemini-api/docs/billing" 
             target="_blank" 
             rel="noopener noreferrer"
             className="inline-flex items-center gap-1 text-[10px] text-indigo-400 hover:text-indigo-300 transition-colors"
           >
              <span>Billing Documentation</span>
              <ExternalLink size={10} />
           </a>
          <p className="text-[10px] text-slate-500">Protected by Azure Active Directory • RBAC Enabled</p>
        </div>
      </div>
    </div>
  );
};
