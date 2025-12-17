import React from 'react';
import { Code, Mail, Globe, ShieldCheck, Server } from 'lucide-react';

export const About: React.FC = () => {
  return (
    <div className="p-8 h-full overflow-y-auto">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-12">
            <h1 className="text-4xl font-bold text-white mb-4">System Manifest</h1>
            <p className="text-slate-400 max-w-2xl mx-auto">
                GrAtech AI Nexus is a sovereign operational backbone connected to Azure Subscription 1 (dde8...2c44).
            </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mb-16">
            <div className="space-y-6">
                <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
                    <div className="w-12 h-12 bg-indigo-500/20 rounded-xl flex items-center justify-center mb-4">
                        <ShieldCheck className="text-indigo-400" size={24} />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-2">Global Topology</h3>
                    <div className="text-slate-400 text-sm">
                        Operating across 4 strategic regions:
                        <ul className="list-disc list-inside mt-2 text-xs text-slate-500">
                            <li>**West US:** Core Compute (VMs)</li>
                            <li>**East US / East US 2:** AI Foundry & Data</li>
                            <li>**Australia East:** Geo-Redundancy</li>
                            <li>**UAE North:** Telemetry</li>
                        </ul>
                    </div>
                </div>
                <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
                    <div className="w-12 h-12 bg-violet-500/20 rounded-xl flex items-center justify-center mb-4">
                        <Server className="text-violet-400" size={24} />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-2">Active Foundry Fleet</h3>
                    <div className="text-slate-400 text-sm">
                        5 Active AI Service Instances powering the GrAxOS Neural Core:
                        <ul className="list-disc list-inside mt-2 text-xs text-slate-500">
                            <li>gratech-openai</li>
                            <li>cometx-openai</li>
                            <li>admin-1533-resource</li>
                            <li>gratechagent-1-resource</li>
                            <li>admin-0242-resource</li>
                        </ul>
                    </div>
                </div>
            </div>

            {/* Contact Form */}
            <div className="bg-slate-900 border border-slate-800 p-8 rounded-3xl relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/10 rounded-full blur-3xl -mr-16 -mt-16"></div>
                <h3 className="text-2xl font-bold text-white mb-6">Contact Engineering</h3>
                <form className="space-y-4">
                    <div>
                        <label className="block text-xs font-medium text-slate-400 mb-1">Identity</label>
                        <input type="text" className="w-full bg-slate-800 border border-slate-700 rounded-lg p-3 text-white text-sm focus:ring-1 focus:ring-indigo-500 outline-none" placeholder="Agent ID or Name" />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-slate-400 mb-1">Transmission</label>
                        <textarea className="w-full bg-slate-800 border border-slate-700 rounded-lg p-3 text-white text-sm focus:ring-1 focus:ring-indigo-500 outline-none" rows={4} placeholder="Describe the anomaly..." />
                    </div>
                    <button type="button" className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-3 rounded-lg transition-colors shadow-lg shadow-indigo-500/20">
                        Send Secure Message
                    </button>
                </form>
            </div>
        </div>

        {/* Footer info */}
        <div className="border-t border-slate-800 pt-8 flex flex-col md:flex-row justify-between items-center text-sm text-slate-500">
            <div className="flex items-center gap-6 mb-4 md:mb-0">
                <span className="flex items-center gap-2"><Code size={14} /> v2.5.0-foundry</span>
                <span className="flex items-center gap-2"><Globe size={14} /> gratech.sa</span>
            </div>
            <p>© 2024 GrAtech AI Nexus. All rights reserved.</p>
        </div>
      </div>
    </div>
  );
};
