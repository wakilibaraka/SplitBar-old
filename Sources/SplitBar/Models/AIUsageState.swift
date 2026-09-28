import Foundation

public enum AIActivityStatus: String, Codable, Equatable, Sendable {
    case completed
    case running
    case queued
    case idle
}

public enum AIAgentType: String, Codable, CaseIterable, Sendable {
    case claude = "Claude Code"
    case codex = "OpenAI Codex"
    case opencode = "OpenCode"
    case ollama = "Ollama (Local)"

    public var systemIcon: String {
        switch self {
        case .claude:
            return "brain.head.profile"
        case .codex:
            return "chevron.left.forwardslash.chevron.right"
        case .opencode:
            return "terminal.fill"
        case .ollama:
            return "cpu.fill"
        }
    }
}

public struct AIAgentSession: Identifiable, Equatable, Sendable {
    public let id: String
    public let agentType: AIAgentType
    public let isRunning: Bool
    public let pid: Int32?
    public let activeDirectory: String?
    public let modelName: String
    public let lastTaskPrompt: String?
    public let lastActivityTime: Date?
    public let costOrTokenSummary: String?

    public init(
        id: String,
        agentType: AIAgentType,
        isRunning: Bool,
        pid: Int32?,
        activeDirectory: String?,
        modelName: String,
        lastTaskPrompt: String?,
        lastActivityTime: Date?,
        costOrTokenSummary: String?
    ) {
        self.id = id
        self.agentType = agentType
        self.isRunning = isRunning
        self.pid = pid
        self.activeDirectory = activeDirectory
        self.modelName = modelName
        self.lastTaskPrompt = lastTaskPrompt
        self.lastActivityTime = lastActivityTime
        self.costOrTokenSummary = costOrTokenSummary
    }
}

public struct AIActivityItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let modelName: String
    public let timestamp: Date
    public let status: AIActivityStatus
    public let tokenCount: Int

    public init(
        id: String,
        title: String,
        modelName: String,
        timestamp: Date,
        status: AIActivityStatus,
        tokenCount: Int
    ) {
        self.id = id
        self.title = title
        self.modelName = modelName
        self.timestamp = timestamp
        self.status = status
        self.tokenCount = tokenCount
    }
}

public struct AIUsageState: Equatable, Sendable {
    public let agentSessions: [AIAgentSession]
    public let limitCards: [ProviderLimitCard]
    public let dailyUsage: [DailyTokenUsage]
    public let ollamaModels: [OllamaLoadedModel]
    public let recentActivities: [AIActivityItem]
    public let isPrivacyPreserving: Bool
    public let lastUpdated: Date

    public init(
        agentSessions: [AIAgentSession],
        limitCards: [ProviderLimitCard],
        dailyUsage: [DailyTokenUsage],
        ollamaModels: [OllamaLoadedModel],
        recentActivities: [AIActivityItem],
        isPrivacyPreserving: Bool,
        lastUpdated: Date
    ) {
        self.agentSessions = agentSessions
        self.limitCards = limitCards
        self.dailyUsage = dailyUsage
        self.ollamaModels = ollamaModels
        self.recentActivities = recentActivities
        self.isPrivacyPreserving = isPrivacyPreserving
        self.lastUpdated = lastUpdated
    }

    /// Henüz hiçbir yerel veri okunmamış başlangıç durumu.
    public static let empty = AIUsageState(
        agentSessions: [],
        limitCards: [],
        dailyUsage: [],
        ollamaModels: [],
        recentActivities: [],
        isPrivacyPreserving: true,
        lastUpdated: Date.distantPast
    )

    public var hasRunningAgent: Bool {
        agentSessions.contains(where: { $0.isRunning })
    }

    /// Aktif hesaplar arasında en az kalan 5 saatlik kota (en kritik olan); dock rozetinde gösterilir.
    public func lowestFiveHourRemainingPercent(now: Date) -> Double? {
        limitCards
            .compactMap { $0.limits?.fiveHour }
            .map { 100.0 - effectiveUsedPercent(window: $0, now: now) }
            .min()
    }

    public static func defaultSample() -> AIUsageState {
        let sampleSessions = [
            AIAgentSession(
                id: "agent-claude",
                agentType: .claude,
                isRunning: true,
                pid: 29647,
                activeDirectory: "~/Projects/sample-app",
                modelName: "claude-opus-5-5",
                lastTaskPrompt: "login session",
                lastActivityTime: Date(),
                costOrTokenSummary: "Active Session"
            ),
            AIAgentSession(
                id: "agent-codex",
                agentType: .codex,
                isRunning: true,
                pid: 36855,
                activeDirectory: nil,
                modelName: "Codex App Server",
                lastTaskPrompt: "Summarize Guard routing rules",
                lastActivityTime: Date().addingTimeInterval(-600),
                costOrTokenSummary: "Shared Daemon"
            ),
            AIAgentSession(
                id: "agent-opencode",
                agentType: .opencode,
                isRunning: false,
                pid: nil,
                activeDirectory: "~/Projects/opencode-workspace",
                modelName: "space-bunny-free",
                lastTaskPrompt: "New session",
                lastActivityTime: Date().addingTimeInterval(-3600),
                costOrTokenSummary: "opencode.db"
            ),
            AIAgentSession(
                id: "agent-ollama",
                agentType: .ollama,
                isRunning: true,
                pid: 24724,
                activeDirectory: "127.0.0.1:11434",
                modelName: "gpt-oss:20b-cloud",
                lastTaskPrompt: "Local On-Device Inference Ready",
                lastActivityTime: Date(),
                costOrTokenSummary: "Local Memory"
            )
        ]

        let activities = [
            AIActivityItem(
                id: "a1",
                title: "Code Completion & Refactoring",
                modelName: "Llama-3.2-3B",
                timestamp: Date(),
                status: .completed,
                tokenCount: 840
            ),
            AIActivityItem(
                id: "a2",
                title: "Markdown Document Summarization",
                modelName: "Claude 3.5 Sonnet",
                timestamp: Date().addingTimeInterval(-300),
                status: .completed,
                tokenCount: 1650
            ),
            AIActivityItem(
                id: "a3",
                title: "Local Embedding Generation",
                modelName: "On-Device Foundation",
                timestamp: Date().addingTimeInterval(-1200),
                status: .idle,
                tokenCount: 320
            )
        ]

        return AIUsageState(
            agentSessions: sampleSessions,
            limitCards: [],
            dailyUsage: [],
            ollamaModels: [],
            recentActivities: activities,
            isPrivacyPreserving: true,
            lastUpdated: Date()
        )
    }
}
