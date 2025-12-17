export interface SystemMetrics {
    totalRequests: number;
    totalTokens: number;
    errors: number;
    averageLatency: number;
    requestsByModel: Record<string, number>;
    history: { timestamp: number; latency: number; tokens: number }[];
}

export const monitoringService = {
    subscribe: (callback: (metrics: SystemMetrics) => void) => {
        // Simulate real-time updates
        const interval = setInterval(() => {
            const metrics: SystemMetrics = {
                totalRequests: Math.floor(Math.random() * 10000),
                totalTokens: Math.floor(Math.random() * 1000000),
                errors: Math.floor(Math.random() * 50),
                averageLatency: Math.floor(Math.random() * 500) + 100,
                requestsByModel: {
                    'gpt-4': Math.floor(Math.random() * 5000),
                    'gemini-pro': Math.floor(Math.random() * 3000),
                    'claude-3': Math.floor(Math.random() * 2000)
                },
                history: Array.from({ length: 20 }, (_, i) => ({
                    timestamp: Date.now() - (19 - i) * 60000,
                    latency: Math.floor(Math.random() * 500) + 100,
                    tokens: Math.floor(Math.random() * 1000)
                }))
            };
            callback(metrics);
        }, 2000);

        return () => clearInterval(interval);
    }
};
