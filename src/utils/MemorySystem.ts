import { GoogleGenAI } from "@google/genai";
import { Message, MemoryEntry, KnowledgeNode, MemoryItem } from '../types';

// Arabic Stopwords for NLP (Expanded)
const AR_STOP_WORDS = new Set([
  'في', 'من', 'على', 'إلى', 'عن', 'مع', 'ان', 'أن', 'إن', 'لا', 'لم', 'لن', 'ما',
  'هذا', 'هذه', 'تم', 'كان', 'كانت', 'يكون', 'التي', 'الذي', 'الذين', 'ذلك', 
  'و', 'أو', 'ثم', 'حيث', 'كل', 'بعد', 'قبل', 'عند', 'بين', 'كما', 'لكن', 'هل', 
  'كيف', 'كم', 'متى', 'لماذا', 'لماذا', 'هو', 'هي', 'هم', 'نحن', 'أنا', 'يا', 'سوف', 'قد',
  'جدا', 'ايضا', 'فيه', 'عليه', 'إليها', 'عنها', 'منها', 'لها', 'بها'
]);

// TF-IDF Index Structure
interface InvertedIndex {
    [term: string]: number; // DF (Document Frequency)
}

class MemoryNexus {
  private static instance: MemoryNexus;
  private readonly STORAGE_KEY_CHAT = 'gratech_nexus_chat';
  private readonly STORAGE_KEY_KNOWLEDGE = 'gratech_nexus_knowledge';
  private readonly STORAGE_KEY_LOGS = 'gratech_nexus_logs';
  private readonly STORAGE_KEY_LTM = 'gratech_nexus_ltm'; // Long Term Memory
  
  // In-memory IDF Cache to avoid re-calculating on every request
  private termIndex: InvertedIndex = {};
  private idfCache: Record<string, number> = {};
  private totalDocuments: number = 0;
  
  // Real Neural Core
  private genAI: GoogleGenAI;
  private hasApiKey: boolean = false;

  private constructor() {
    this.initializeSystem();
    this.rebuildIndex();
    
    const apiKey = process.env.API_KEY || '';
    this.hasApiKey = !!apiKey;
    this.genAI = new GoogleGenAI({ apiKey });
  }

  public static getInstance(): MemoryNexus {
    if (!MemoryNexus.instance) {
      MemoryNexus.instance = new MemoryNexus();
    }
    return MemoryNexus.instance;
  }

  public isNeuralCoreActive(): boolean {
    return this.hasApiKey;
  }

  private initializeSystem() {
    if (!localStorage.getItem(this.STORAGE_KEY_CHAT)) {
      this.logSystemEvent('Initializing Neural Core v5.1 (Arsenal Enhanced)...');
      this.logSystemEvent('Mounting GrAxOS Enterprise Context...');
      localStorage.setItem(this.STORAGE_KEY_CHAT, JSON.stringify([]));
    }
    if (!localStorage.getItem(this.STORAGE_KEY_KNOWLEDGE)) {
      const seedKnowledge: KnowledgeNode[] = [
        { key: 'org_name', value: 'GrAxOS (SULIMAN NAZAL ALSHAMMARI)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'infra_dns', value: 'gratech.sa (Azure DNS / Global)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'vault_prod', value: 'gratechkvprod (East US 2)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'ai_primary', value: 'gratech-openai (East US) - gpt-4o/gpt-4.1', confidence: 1.0, extractedAt: Date.now() },
        { key: 'ai_comet', value: 'cometx-openai (East US 2)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'ai_agent', value: 'gratechagent-1-resource (East US 2) - DeepSeek-R1', confidence: 1.0, extractedAt: Date.now() },
        { key: 'ai_admin1533', value: 'admin-1533-resource (East US 2) - Claude Sonnet/Opus 4.5', confidence: 1.0, extractedAt: Date.now() },
        { key: 'ai_admin0242', value: 'admin-0242-resource (Australia East) - Llama-4-Maverick', confidence: 1.0, extractedAt: Date.now() },
        { key: 'log_workspace', value: 'workspace-rggratechcomet8eal (East US)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'storage_diag', value: 'stgratechcometweb (East US)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'memory_store', value: 'deepseek-memory (Cosmos DB / East US)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'vm_prod', value: 'vm-gratech-prod (104.42.143.26 / West US)', confidence: 1.0, extractedAt: Date.now() },
        { key: 'vm_edge', value: 'vm-ubuntu-edge (20.59.71.1 / West US / EdgeZone)', confidence: 1.0, extractedAt: Date.now() },
      ];
      localStorage.setItem(this.STORAGE_KEY_KNOWLEDGE, JSON.stringify(seedKnowledge));
    }
    if (!localStorage.getItem(this.STORAGE_KEY_LTM)) {
      localStorage.setItem(this.STORAGE_KEY_LTM, JSON.stringify([]));
    }
  }

  // --- Core Memory Operations ---

  public getChatHistory(): Message[] {
    const data = localStorage.getItem(this.STORAGE_KEY_CHAT);
    if (!data) return [];
    try {
      const parsed = JSON.parse(data);
      return parsed.map((m: any) => ({
        ...m,
        timestamp: new Date(m.timestamp)
      }));
    } catch (e) {
      return [];
    }
  }

  public saveMessage(message: Message) {
    const history = this.getChatHistory();
    const updatedHistory = [...history, message].slice(-100);
    localStorage.setItem(this.STORAGE_KEY_CHAT, JSON.stringify(updatedHistory));
    
    // Auto-save user messages to LTM if substantial
    if (message.sender === 'user') {
      this.extractKnowledge(message.text);
      if (message.text.length > 20) {
          this.saveLongTermMemory({
              id: `msg_${Date.now()}`,
              content: message.text,
              type: 'conversation',
              timestamp: Date.now(),
              tags: this.generateTags(message.text),
              category: 'FACT'
          });
      }
    }
  }

  public clearMemory() {
    localStorage.removeItem(this.STORAGE_KEY_CHAT);
    localStorage.removeItem(this.STORAGE_KEY_KNOWLEDGE);
    localStorage.removeItem(this.STORAGE_KEY_LOGS);
    localStorage.removeItem(this.STORAGE_KEY_LTM);
    this.initializeSystem();
    this.rebuildIndex();
    this.logSystemEvent('Memory core wiped. System reset to factory defaults.');
    return [];
  }

  // --- Intelligent Knowledge Graph ---

  public getKnowledgeGraph(): KnowledgeNode[] {
    const data = localStorage.getItem(this.STORAGE_KEY_KNOWLEDGE);
    return data ? JSON.parse(data) : [];
  }

  private saveKnowledgeNode(node: KnowledgeNode) {
    const graph = this.getKnowledgeGraph();
    const index = graph.findIndex(n => n.key === node.key);
    if (index >= 0) {
      graph[index] = node;
    } else {
      graph.push(node);
    }
    localStorage.setItem(this.STORAGE_KEY_KNOWLEDGE, JSON.stringify(graph));
    this.logSystemEvent(`Neural Link Established: [${node.key}]`);
  }

  private extractKnowledge(text: string) {
    const lower = text.toLowerCase();
    if (lower.includes('name is') || text.includes('اسمي')) {
      const name = text.includes('اسمي') ? text.split('اسمي')[1] : text.split('name is')[1];
      this.saveKnowledgeNode({ key: 'user_name', value: name.trim().replace(/[.,،]/g, ''), confidence: 0.99, extractedAt: Date.now() });
    }
  }

  // --- Long Term Memory & Indexing ---

  public getLongTermMemory(): MemoryEntry[] {
    const data = localStorage.getItem(this.STORAGE_KEY_LTM);
    return data ? JSON.parse(data) : [];
  }

  public saveLongTermMemory(entry: MemoryEntry) {
    const memory = this.getLongTermMemory();
    const existingIndex = memory.findIndex(m => m.id === entry.id);
    if (existingIndex >= 0) {
        memory[existingIndex] = entry;
    } else {
        memory.push(entry);
    }
    localStorage.setItem(this.STORAGE_KEY_LTM, JSON.stringify(memory));
    this.indexEntry(entry);
  }

  public deleteMemory(id: string): MemoryItem[] {
      const memory = this.getLongTermMemory();
      const updated = memory.filter(m => m.id !== id);
      localStorage.setItem(this.STORAGE_KEY_LTM, JSON.stringify(updated));
      this.rebuildIndex();
      return this.mapToMemoryItem(updated);
  }

  // UI Helper for ChatBot integration
  public mapToMemoryItem(entries: MemoryEntry[]): MemoryItem[] {
      return entries.map(e => ({
          id: e.id,
          content: e.content,
          category: e.category || 'FACT',
          timestamp: e.timestamp
      }));
  }

  public getContextString(limit: number): string {
      const memory = this.getLongTermMemory();
      // Simple strategy: recent memories
      return memory
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, limit)
        .map(m => `[${m.category || 'FACT'}] ${m.content}`)
        .join('\n');
  }

  // Rebuilds the Inverted Index for TF-IDF from scratch
  private rebuildIndex() {
      const memory = this.getLongTermMemory();
      this.totalDocuments = memory.length;
      this.termIndex = {};
      this.idfCache = {};

      memory.forEach(entry => {
          const tokens = new Set(this.tokenize(entry.content));
          tokens.forEach(token => {
              this.termIndex[token] = (this.termIndex[token] || 0) + 1;
          });
      });

      // Pre-calculate IDF
      Object.keys(this.termIndex).forEach(term => {
          const df = this.termIndex[term];
          this.idfCache[term] = Math.log(this.totalDocuments / (df || 1));
      });
  }

  private indexEntry(entry: MemoryEntry) {
      const tokens = new Set(this.tokenize(entry.content));
      let dirty = false;
      tokens.forEach(token => {
          if (!this.termIndex[token]) {
             this.termIndex[token] = 0;
             dirty = true;
          }
          this.termIndex[token]++;
      });
      this.totalDocuments++;
      if (dirty) this.rebuildIndex();
  }

  // --- NLP Utilities ---

  private normalizeArabic(text: string): string {
    return text
      .replace(/[إأآ]/g, 'ا')
      .replace(/ى/g, 'ي')
      .replace(/ة/g, 'ه')
      .replace(/[\u064B-\u065F]/g, '') // Remove Tashkeel
      .replace(/[^\w\s\u0600-\u06FF]/g, ' '); // Remove punctuation
  }

  private stemArabic(word: string): string {
    let w = word;
    if (w.length <= 3) return w;
    if (w.startsWith('ال')) w = w.substring(2);
    if (w.startsWith('و') && w.length > 3) w = w.substring(1);
    if (w.endsWith('ات')) w = w.substring(0, w.length - 2);
    if (w.endsWith('ين')) w = w.substring(0, w.length - 2);
    if (w.endsWith('ة')) w = w.substring(0, w.length - 1);
    
    return w;
  }

  private isArabic(text: string): boolean {
    return /[\u0600-\u06FF]/.test(text);
  }

  private tokenize(text: string): string[] {
    const normalized = this.normalizeArabic(text.toLowerCase());
    return normalized.split(/\s+/)
      .map(w => w.trim())
      .filter(w => w.length > 2 && !AR_STOP_WORDS.has(w))
      .map(w => this.isArabic(w) ? this.stemArabic(w) : w);
  }

  public generateTags(text: string): string[] {
    const tokens = this.tokenize(text);
    if (tokens.length === 0) return [];

    const tf: Record<string, number> = {};
    tokens.forEach(t => tf[t] = (tf[t] || 0) + 1);

    const scores = Object.keys(tf).map(term => {
        const idf = this.idfCache[term] || Math.log(this.totalDocuments + 1); 
        return { term, score: tf[term] * idf };
    });

    return scores.sort((a, b) => b.score - a.score).slice(0, 5).map(s => s.term);
  }

  // --- GitHub Integration ---

  public async syncGitHub(token: string, owner: string, repo: string) {
    this.logSystemEvent(`Initiating GitHub Sync for ${owner}/${repo}...`);
    const headers = {
        'Authorization': `token ${token}`,
        'Accept': 'application/vnd.github.v3+json'
    };

    try {
        const issuesRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/issues?state=all&per_page=30`, { headers });
        if (issuesRes.ok) {
            const issues = await issuesRes.json();
            let count = 0;
            issues.forEach((issue: any) => {
                const content = `${issue.title} ${issue.body || ''}`;
                const tags = this.generateTags(content);
                const entry: MemoryEntry = {
                    id: `gh_${issue.id}`,
                    content: `GitHub ${issue.pull_request ? 'PR' : 'Issue'} #${issue.number}: ${issue.title}\n${issue.body || ''}`,
                    type: issue.pull_request ? 'github_pr' : 'github_issue',
                    timestamp: new Date(issue.created_at).getTime(),
                    tags: [...tags, 'github', repo, issue.state, issue.pull_request ? 'pr' : 'issue'],
                    metadata: { url: issue.html_url, user: issue.user.login, state: issue.state },
                    category: 'FACT'
                };
                this.saveLongTermMemory(entry);
                count++;
            });
            this.rebuildIndex();
            this.logSystemEvent(`Synced ${count} items from GitHub.`);
            return { success: true, count };
        } else {
            throw new Error(`GitHub API Error: ${issuesRes.statusText}`);
        }
    } catch (e: any) {
        this.logSystemEvent(`GitHub Sync failed: ${e.message}`);
        return { success: false, error: e.message };
    }
  }

  public async generateResponse(userText: string): Promise<Message> {
    const knowledge = this.getKnowledgeGraph();
    const memory = this.getLongTermMemory();
    
    // Auto Response for system status
    if (userText.includes('/system_status') || userText.includes('تقرير النظام')) {
         const dumpText = `**⚠️ SYSTEM SECURITY DUMP**\nActive Nodes: 5\nCost: $600.00\nSecure Score: 13%`;
        return {
            id: (Date.now() + 1).toString(),
            sender: 'agent',
            agentName: 'GrAxOS Core',
            text: dumpText,
            timestamp: new Date(),
            metadata: { processingTime: 10, memoryAccessed: true }
        };
    }
    
    const tags = this.generateTags(userText);
    const relevantMemories = memory
        .filter(m => m.tags.some(t => tags.includes(t)))
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, 3);
        
    try {
        if (!this.hasApiKey) throw new Error("Missing Key");

        const response = await this.genAI.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: userText
        });

        return {
            id: (Date.now() + 1).toString(),
            sender: 'agent',
            agentName: 'GrAxOS Core',
            text: response.text || "No response",
            timestamp: new Date(),
            metadata: {
                processingTime: 450,
                memoryAccessed: relevantMemories.length > 0,
                sources: ['Gemini-2.5-Flash']
            }
        };

    } catch (e) {
        return {
            id: (Date.now() + 1).toString(),
            sender: 'agent',
            agentName: 'GrAxOS Core',
            text: "Neural Core Offline. Simulated response.",
            timestamp: new Date()
        };
    }
  }

  // --- Logging ---

  public logSystemEvent(message: string) {
    const logs = this.getSystemLogs();
    logs.unshift({
        id: Date.now().toString(),
        content: message,
        type: 'system_log',
        timestamp: Date.now(),
        tags: ['system'],
        category: 'FACT'
    });
    localStorage.setItem(this.STORAGE_KEY_LOGS, JSON.stringify(logs.slice(0, 50)));
  }

  public getSystemLogs(): MemoryEntry[] {
    const data = localStorage.getItem(this.STORAGE_KEY_LOGS);
    return data ? JSON.parse(data) : [];
  }
}

export const memoryNexus = MemoryNexus.getInstance();

// Export facade for new ChatBot UI
export const memoryService = {
    load: () => memoryNexus.mapToMemoryItem(memoryNexus.getLongTermMemory()),
    add: (category: 'FACT' | 'PREF' | 'TASK', content: string) => {
        const entry: MemoryEntry = {
            id: Date.now().toString(),
            content,
            category,
            type: 'fact',
            timestamp: Date.now(),
            tags: memoryNexus.generateTags(content)
        };
        memoryNexus.saveLongTermMemory(entry);
        return { id: entry.id, content, category, timestamp: entry.timestamp };
    },
    delete: (id: string) => memoryNexus.deleteMemory(id),
    clear: () => memoryNexus.mapToMemoryItem(memoryNexus.clearMemory()),
    getContextString: (limit: number) => memoryNexus.getContextString(limit),
    syncGitHub: (token: string, owner: string, repo: string) => memoryNexus.syncGitHub(token, owner, repo)
};

// Export original instance as memorySystem for compatibility
export const memorySystem = memoryNexus;
