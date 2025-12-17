export type ViewState = 
  | 'dashboard' 
  | 'chat' 
  | 'live' 
  | 'orchestrator' 
  | 'app-factory' 
  | 'ide' 
  | 'tasks' 
  | 'portal' 
  | 'resources' 
  | 'about' 
  | 'performance' 
  | 'notifications' 
  | 'settings';

export type Language = 'en' | 'ar';

export type ModelType = 'fast' | 'standard' | 'smart';

export enum MessageType {
  TEXT = 'text',
  IMAGE = 'image',
  VIDEO = 'video'
}

export interface Message {
  id: string;
  timestamp: Date;
  createdAt?: Date;
  role?: 'user' | 'assistant' | 'system';
  sender: 'user' | 'agent' | 'system';
  agentName?: string;
  text: string;
  content?: { text: string };
  image?: string;
  video?: string;
  status?: 'sent' | 'delivered' | 'read' | 'failed';
  type?: MessageType;
  context?: {
    tokens: { prompt: number; completion: number; total: number };
    model: string;
  };
  modelUsed?: string;
  isThinking?: boolean;
  metadata?: {
    sources?: string[];
    memoryAccessed?: boolean;
    processingTime?: number;
    [key: string]: any;
  };
}

export interface MemoryItem {
  id: string;
  content: string;
  category: 'FACT' | 'PREF' | 'TASK';
  timestamp: number;
}

export interface MemoryEntry {
    id: string;
    content: string;
    category: 'FACT' | 'PREF' | 'TASK';
    type: string;
    timestamp: number;
    tags: string[];
    metadata?: any;
}

export interface KnowledgeNode {
    key: string;
    value: string;
    confidence: number;
    extractedAt: number;
}

export interface NotificationItem {
  id: number;
  type: 'success' | 'warning' | 'error' | 'info';
  message: string;
  time: string;
}
