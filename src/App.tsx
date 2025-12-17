import React, { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Login } from './components/Login';
import { LandingPage } from './components/LandingPage';
import { Dashboard } from './components/Dashboard';
import { ChatInterface } from './components/ChatInterface';
import { Portal } from './components/Portal';
import { Resources } from './components/Resources';
import { About } from './components/About';
import { PerformanceMonitor } from './components/PerformanceMonitor';
import { Notifications } from './components/Notifications';
import { Settings } from './components/Settings';
import { TaskManager } from './components/TaskManager';
import { IDELayout } from './components/ide/IDELayout';
import { OrchestratorUI } from './components/orchestrator/OrchestratorUI';
import { AppFactoryUI } from './components/factory/AppFactoryUI';
import { LiveSession } from './components/LiveSession';
import { ToastContainer } from './components/ToastContainer';
import { ViewState, Language } from './types';
import { Menu } from 'lucide-react';

function App() {
  const [appState, setAppState] = useState<'landing' | 'login' | 'app'>('landing');
  const [currentView, setCurrentView] = useState<ViewState>('dashboard');
  const [language, setLanguage] = useState<Language>('en');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  if (appState === 'landing') {
    return <LandingPage onEnter={() => setAppState('login')} />;
  }

  if (appState === 'login') {
    return (
      <>
        <Login onLogin={() => setAppState('app')} />
        <ToastContainer />
      </>
    );
  }

  const renderView = () => {
    // Pass language prop to components that need it
    switch (currentView) {
      case 'dashboard': return <Dashboard />;
      case 'chat': return <ChatInterface />;
      case 'live': return <LiveSession />;
      case 'orchestrator': return <OrchestratorUI />;
      case 'app-factory': return <AppFactoryUI />;
      case 'ide': return <IDELayout />;
      case 'tasks': return <TaskManager />;
      case 'portal': return <Portal />;
      case 'resources': return <Resources language={language} />;
      case 'about': return <About />;
      case 'performance': return <PerformanceMonitor />;
      case 'notifications': return <Notifications />;
      case 'settings': return <Settings />;
      default: return <Dashboard />;
    }
  };

  return (
    <div className="flex h-screen bg-slate-950 text-slate-50 overflow-hidden" dir={language === 'ar' ? 'rtl' : 'ltr'}>
      <ToastContainer />
      
      {/* Mobile Header */}
      <div className="lg:hidden fixed top-0 left-0 right-0 h-16 bg-slate-950/80 backdrop-blur-md border-b border-slate-800 z-40 flex items-center px-4 justify-between">
          <button 
            onClick={() => setIsSidebarOpen(true)}
            className="p-2 text-slate-400 hover:text-white"
          >
              <Menu size={24} />
          </button>
          <span className="font-bold text-white">CometX</span>
          <div className="w-8"></div> {/* Spacer for centering */}
      </div>

      <Sidebar 
        currentView={currentView} 
        onChangeView={setCurrentView} 
        onLogout={() => setAppState('login')}
        language={language}
        onLanguageChange={setLanguage}
        isOpen={isSidebarOpen}
        onClose={() => setIsSidebarOpen(false)}
      />
      
      <main className="flex-1 relative overflow-hidden flex flex-col pt-16 lg:pt-0">
        {/* Top Gradient Glow (Hidden in specialized modes for full immersion) */}
        {currentView !== 'ide' && currentView !== 'orchestrator' && currentView !== 'app-factory' && (
             <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-indigo-500 via-violet-500 to-emerald-500 shadow-[0_0_20px_rgba(99,102,241,0.5)] z-10 hidden lg:block"></div>
        )}
        {renderView()}
      </main>
    </div>
  );
}

export default App;
