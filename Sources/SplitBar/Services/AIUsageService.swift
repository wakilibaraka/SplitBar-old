import AppKit
import Foundation
import OSLog

@MainActor
public final class AIUsageService {
    public private(set) var currentState: AIUsageState
    private var refreshTimer: Timer?
    private let accountStore: AIAccountStore
    private let usageScanner: ProviderUsageScanner
    public let claudeBridge: ClaudeStatusLineBridge
    private var refreshTask: Task<Void, Never>?
    private var lastProcessTable: [(pid: Int32, command: String)] = []
    /// Hesap/limit okuması ve token geçmişi taraması süreç taramasından daha seyrek yapılır.
    private var lastLimitRefresh: Date = .distantPast
    private var lastUsageScan: Date = .distantPast
    private static let limitRefreshInterval: TimeInterval = 20.0
    private static let usageScanInterval: TimeInterval = 300.0

    public init(
        initialState: AIUsageState,
        accountStore: AIAccountStore,
        usageScanner: ProviderUsageScanner,
        claudeBridge: ClaudeStatusLineBridge
    ) {
        self.currentState = initialState
        self.accountStore = accountStore
        self.usageScanner = usageScanner
        self.claudeBridge = claudeBridge
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil && NSClassFromString("XCTestCase") == nil {
            Task { [weak self] in
                await self?.refresh()
            }
            self.startPeriodicUpdates()
        }
    }

    public func startLiveMonitoring(
        interval: TimeInterval,
        onUpdate: @escaping @MainActor @Sendable (AIUsageState) -> Void
    ) {
        stopPeriodicUpdates()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.refresh()
                onUpdate(self.currentState)
            }
        }
    }

    public func stopPeriodicUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func startPeriodicUpdates() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    public func sampleUsage() -> AIUsageState {
        return currentState
    }

    public func recordActivity(
        title: String,
        modelName: String,
        tokenCount: Int,
        status: AIActivityStatus
    ) {
        let newActivity = AIActivityItem(
            id: UUID().uuidString,
            title: title,
            modelName: modelName,
            timestamp: Date(),
            status: status,
            tokenCount: tokenCount
        )

        var updatedActivities = currentState.recentActivities
        updatedActivities.insert(newActivity, at: 0)

        self.currentState = AIUsageState(
            agentSessions: currentState.agentSessions,
            limitCards: currentState.limitCards,
            dailyUsage: currentState.dailyUsage,
            ollamaModels: currentState.ollamaModels,
            recentActivities: updatedActivities,
            isPrivacyPreserving: currentState.isPrivacyPreserving,
            lastUpdated: Date()
        )
    }

    /// Zamanlayıcı tetiklemeleri için: önceki tarama sürüyorsa bu tetikleme atlanır.
    public func refresh() async {
        guard refreshTask == nil else { return }
        await runRefresh()
    }

    /// Kullanıcı eylemleri için: süren tarama bitene kadar beklenir ve ardından mutlaka yeni tarama yapılır.
    private func forceRefresh() async {
        while let inFlight = refreshTask {
            await inFlight.value
        }
        await runRefresh()
    }

    private func runRefresh() async {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performRefresh()
        }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    private func performRefresh() async {
        let now = Date()

        // 1. Inspect running processes via ps
        let runningProcessTable = await fetchRunningProcessTable()
        lastProcessTable = runningProcessTable

        // 2. Discover Claude Code Session
        let claudeSession = await inspectClaudeSession(processTable: runningProcessTable)

        // 3. Discover OpenAI Codex Session
        let codexSession = await inspectCodexSession(processTable: runningProcessTable)

        // 4. Discover OpenCode Session
        let openCodeSession = await inspectOpenCodeSession(processTable: runningProcessTable)

        // 5. Discover Ollama Engine & Models
        let (ollamaSession, ollamaModels) = await inspectOllama(processTable: runningProcessTable)

        let sessions = [claudeSession, codexSession, openCodeSession, ollamaSession]

        // 6. Hesaplar ve gerçek plan limitleri
        let limitCards: [ProviderLimitCard]
        if now.timeIntervalSince(lastLimitRefresh) >= Self.limitRefreshInterval {
            limitCards = await loadLimitCards(sessions: sessions, now: now)
            lastLimitRefresh = now
        } else {
            limitCards = currentState.limitCards.map { card in
                withRunningState(card, sessions: sessions)
            }
        }

        // 7. Son 7 günün token tüketimi (artımlı tarama)
        let dailyUsage: [DailyTokenUsage]
        if now.timeIntervalSince(lastUsageScan) >= Self.usageScanInterval {
            dailyUsage = await usageScanner.dailyTokenUsage(days: 7, now: now)
            lastUsageScan = now
        } else {
            dailyUsage = currentState.dailyUsage
        }

        self.currentState = AIUsageState(
            agentSessions: sessions,
            limitCards: limitCards,
            dailyUsage: dailyUsage,
            ollamaModels: ollamaModels,
            recentActivities: currentState.recentActivities,
            isPrivacyPreserving: true,
            lastUpdated: now
        )
    }

    // MARK: - Accounts & Limits

    /// Hesap geçişi sonrası limitler bir sonraki zamanlayıcıyı beklemeden yeniden okunur.
    /// Hesap geçişi sonrası limitler bir sonraki zamanlayıcıyı beklemeden yeniden okunur. Süreç tablosu
    /// geçişten hemen önce tazelenir ki az önce kapatılan oturumlar hâlâ açık sayılmasın.
    public func switchAccount(to account: AIAccount) async throws {
        lastProcessTable = await fetchRunningProcessTable()
        _ = try await accountStore.switchAccount(to: account, runningSessionCount: runningSessionCount(provider: account.provider))
        lastLimitRefresh = .distantPast
        await forceRefresh()
    }

    /// Sağlayıcının CLI'ını çalıştıran süreç sayısı (Terminal, IDE eklentileri, T3 Code, Codex uygulaması).
    public func runningSessionCount(provider: AIAccountProvider) -> Int {
        let executableName: String
        switch provider {
        case .claude:
            executableName = "claude"
        case .codex:
            executableName = "codex"
        }
        return lastProcessTable.filter { entry in
            let executable = entry.command.split(separator: " ", maxSplits: 1).first.map(String.init) ?? ""
            return (executable as NSString).lastPathComponent == executableName
        }.count
    }

    /// Yeniden giriş gerektiren belirli bir hesap için giriş akışını, mümkünse e-postası önceden doldurulmuş açar.
    public func openReloginInTerminal(account: AIAccount) throws {
        switch account.provider {
        case .claude:
            try runInTerminal(command: "claude auth login --email \(shellQuoted(account.email))")
        case .codex:
            try runInTerminal(command: "codex login")
        }
    }

    public func removeAccount(_ account: AIAccount) async throws {
        _ = try await accountStore.removeAccount(account)
        lastLimitRefresh = .distantPast
        await forceRefresh()
    }

    public func installClaudeLimitBridge() async throws {
        try claudeBridge.install()
        lastLimitRefresh = .distantPast
        await forceRefresh()
    }

    public func uninstallClaudeLimitBridge() async throws {
        try claudeBridge.uninstall()
        lastLimitRefresh = .distantPast
        await forceRefresh()
    }

    /// Yeni hesaba giriş için sağlayıcının kendi giriş akışını Terminal'de başlatır; giriş yapılan hesap
    /// bir sonraki yenilemede SplitBar'e otomatik kaydedilir.
    public func openLoginInTerminal(provider: AIAccountProvider) throws {
        switch provider {
        case .claude:
            try runInTerminal(command: "claude auth login")
        case .codex:
            try runInTerminal(command: "codex login")
        }
    }

    private func withRunningState(_ card: ProviderLimitCard, sessions: [AIAgentSession]) -> ProviderLimitCard {
        ProviderLimitCard(
            provider: card.provider,
            activeAccount: card.activeAccount,
            savedAccounts: card.savedAccounts,
            limits: card.limits,
            savedAccountLimits: card.savedAccountLimits,
            isLimitSourceConnected: card.isLimitSourceConnected,
            isProviderRunning: sessions.first { $0.agentType == card.provider.agentType }?.isRunning ?? false,
            loginIssue: card.loginIssue,
            accountsNeedingLogin: card.accountsNeedingLogin
        )
    }

    private func loadLimitCards(sessions: [AIAgentSession], now: Date) async -> [ProviderLimitCard] {
        let accounts: AIAccountsSnapshot
        do {
            accounts = try await accountStore.synchronize()
        } catch {
            Logger.general.error("AI account sync failed error=\(String(describing: error), privacy: .public)")
            return currentState.limitCards
        }
        var registry = accounts.registry

        // Codex: oturum kayıtları hangi hesaba ait olduğunu taşıdığı için kayıtlı her hesabın limiti ayrı okunur
        let codexLimits = await usageScanner.latestCodexLimitsByAccount(now: now)
        for account in registry.accounts where account.provider == .codex {
            guard let snapshot = codexLimits[account.accountID] else { continue }
            registry = await recordLimits(snapshot, for: account, fallback: registry)
        }

        // T3 Code önbelleği: limitler birkaç dakikada bir tazelenir ve e-postayla saklanır; kayıtlı her hesaba
        // doğrudan bağlanır. Oturum kayıtlarıyla çakışırsa en yeni veri kazanır (recordLimits)
        for provider in AIAccountProvider.allCases {
            let t3Limits = await usageScanner.latestT3LimitsByEmail(provider: provider)
            for account in registry.accounts where account.provider == provider {
                guard let snapshot = t3Limits[account.email.lowercased()] else { continue }
                registry = await recordLimits(snapshot, for: account, fallback: registry)
            }
        }

        // Claude (status line köprüsü): hesap kimliği taşımaz; son hesap geçişinden sonra yakalandıysa aktif hesaba aittir
        if let activeClaude = accounts.activeAccounts[.claude] {
            do {
                if let snapshot = try await usageScanner.latestClaudeLimits(),
                   snapshot.capturedAt > (registry.switchedAt[AIAccountProvider.claude.rawValue] ?? .distantPast) {
                    registry = await recordLimits(snapshot, for: activeClaude, fallback: registry)
                }
            } catch {
                Logger.general.error("Claude limit capture unreadable error=\(String(describing: error), privacy: .public)")
            }
        }

        let hasT3Source = await usageScanner.hasT3Cache(provider: .claude)
        let isBridgeInstalled: Bool
        do {
            isBridgeInstalled = try claudeBridge.isInstalled()
        } catch {
            Logger.general.error("Claude bridge status unreadable error=\(String(describing: error), privacy: .public)")
            isBridgeInstalled = false
        }

        return AIAccountProvider.allCases.map { provider in
            let active = accounts.activeAccounts[provider]
            let saved = registry.accounts.filter { $0.provider == provider }
            return ProviderLimitCard(
                provider: provider,
                activeAccount: active,
                savedAccounts: saved,
                limits: active.flatMap { registry.lastKnownLimits[$0.id] },
                savedAccountLimits: registry.lastKnownLimits.filter { key, _ in saved.contains { $0.id == key } },
                isLimitSourceConnected: provider == .codex || isBridgeInstalled || hasT3Source,
                isProviderRunning: sessions.first { $0.agentType == provider.agentType }?.isRunning ?? false,
                loginIssue: provider == .claude ? accounts.claudeLoginIssue : nil,
                accountsNeedingLogin: registry.accountsNeedingLogin.filter { id in saved.contains { $0.id == id } }
            )
        }
    }

    private func recordLimits(_ snapshot: ProviderLimitSnapshot, for account: AIAccount, fallback: AIAccountRegistry) async -> AIAccountRegistry {
        do {
            return try await accountStore.recordLimits(snapshot, for: account)
        } catch {
            Logger.general.error("Saving limits failed account=\(account.accountID, privacy: .public) error=\(String(describing: error), privacy: .public)")
            return fallback
        }
    }

    // MARK: - Task Dispatcher (Agent Task Delegation)

    public func dispatchTask(
        agentType: AIAgentType,
        prompt: String,
        openTerminal: Bool
    ) async -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Prompt cannot be empty"
        }

        if openTerminal {
            return await launchInTerminal(agentType: agentType, prompt: trimmed)
        } else {
            return await executeLocally(agentType: agentType, prompt: trimmed)
        }
    }

    private func launchInTerminal(agentType: AIAgentType, prompt: String) async -> String {
        let quotedPrompt = shellQuoted(prompt)
        let command: String

        switch agentType {
        case .claude:
            let dir = currentState.agentSessions.first(where: { $0.agentType == .claude })?.activeDirectory ?? NSHomeDirectory()
            command = "cd \(shellQuoted(dir)) && claude -p \(quotedPrompt)"
        case .codex:
            command = "codex exec \(quotedPrompt)"
        case .opencode:
            command = "opencode run \(quotedPrompt)"
        case .ollama:
            let model = currentState.agentSessions.first(where: { $0.agentType == .ollama })?.modelName ?? "gpt-oss:20b-cloud"
            command = "ollama run \(shellQuoted(model)) \(quotedPrompt)"
        }

        do {
            try runInTerminal(command: command)
        } catch {
            return String(describing: error)
        }
        recordActivity(
            title: "Dispatched to \(agentType.rawValue)",
            modelName: agentType.rawValue,
            tokenCount: trimmedTokenEstimate(prompt: prompt),
            status: .running
        )
        return "Task dispatched to Terminal: \(command)"
    }

    /// Komutu yeni bir Terminal penceresinde çalıştırır. Komut AppleScript kaynağına gömülmez, argv ile
    /// aktarılır; böylece AppleScript enjeksiyonu mümkün olmaz (kabuk alıntılaması çağırana aittir).
    private func runInTerminal(command: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e", "on run argv",
            "-e", "tell application \"Terminal\"",
            "-e", "activate",
            "-e", "do script (item 1 of argv)",
            "-e", "end tell",
            "-e", "end run",
            command
        ]
        do {
            try process.run()
        } catch {
            throw SystemSessionActionError.processLaunchFailed(executable: "/usr/bin/osascript", underlying: error)
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            Logger.general.error("osascript failed status=\(process.terminationStatus, privacy: .public)")
            throw SystemSessionActionError.processExitedWithFailure(
                executable: "osascript (Terminal automation — check System Settings › Privacy & Security › Automation)",
                arguments: [],
                status: process.terminationStatus
            )
        }
    }

    private func executeLocally(agentType: AIAgentType, prompt: String) async -> String {
        switch agentType {
        case .ollama:
            let response = await generateResponse(prompt: prompt)
            recordActivity(
                title: "Ollama Query",
                modelName: "Ollama (Local)",
                tokenCount: trimmedTokenEstimate(prompt: prompt) + trimmedTokenEstimate(prompt: response),
                status: .completed
            )
            return response

        case .claude:
            guard let binaryPath = resolveExecutable(named: "claude") else {
                return missingExecutableMessage(name: "claude")
            }
            let dir = currentState.agentSessions.first(where: { $0.agentType == .claude })?.activeDirectory ?? NSHomeDirectory()
            let result = await runCLIProcess(
                executable: binaryPath,
                arguments: ["-p", prompt],
                workingDirectory: dir
            )
            recordActivity(
                title: "Claude Code Task",
                modelName: "Claude Code",
                tokenCount: trimmedTokenEstimate(prompt: prompt) + trimmedTokenEstimate(prompt: result),
                status: .completed
            )
            return result

        case .codex:
            guard let binaryPath = resolveExecutable(named: "codex") else {
                return missingExecutableMessage(name: "codex")
            }
            let result = await runCLIProcess(
                executable: binaryPath,
                arguments: ["exec", prompt],
                workingDirectory: NSHomeDirectory()
            )
            recordActivity(
                title: "Codex Task",
                modelName: "OpenAI Codex",
                tokenCount: trimmedTokenEstimate(prompt: prompt) + trimmedTokenEstimate(prompt: result),
                status: .completed
            )
            return result

        case .opencode:
            guard let binaryPath = resolveExecutable(named: "opencode") else {
                return missingExecutableMessage(name: "opencode")
            }
            let result = await runCLIProcess(
                executable: binaryPath,
                arguments: ["run", prompt],
                workingDirectory: NSHomeDirectory()
            )
            recordActivity(
                title: "OpenCode Task",
                modelName: "OpenCode",
                tokenCount: trimmedTokenEstimate(prompt: prompt) + trimmedTokenEstimate(prompt: result),
                status: .completed
            )
            return result
        }
    }

    public func generateResponse(prompt: String) async -> String {
        guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else {
            return "Invalid Ollama endpoint"
        }

        // Get current selected model
        let model = currentState.agentSessions.first(where: { $0.agentType == .ollama })?.modelName ?? "gpt-oss:20b-cloud"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return "Failed to serialize prompt request"
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return "Ollama returned error or is offline."
            }

            struct OllamaGenerateResponse: Decodable {
                let response: String
            }

            let result = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
            return result.response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Local AI Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Process & File Inspection

    private func fetchRunningProcessTable() async -> [(pid: Int32, command: String)] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/ps")
                process.arguments = ["-axo", "pid,command"]
                let pipe = Pipe()
                process.standardOutput = pipe

                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    guard let output = String(data: data, encoding: .utf8) else {
                        continuation.resume(returning: [])
                        return
                    }

                    var results: [(pid: Int32, command: String)] = []
                    for line in output.components(separatedBy: "\n") {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { continue }
                        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                        if parts.count == 2, let pid = Int32(parts[0]) {
                            results.append((pid: pid, command: String(parts[1])))
                        }
                    }
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func inspectClaudeSession(processTable: [(pid: Int32, command: String)]) async -> AIAgentSession {
        var isRunning = false
        var pid: Int32? = nil
        var modelName = "claude-opus-5-5"
        var activeDirectory: String? = nil

        // Find active claude process
        for proc in processTable {
            let cmd = proc.command
            if (cmd.hasPrefix("claude ") || cmd.contains("/claude ")) && !cmd.contains("grep") && !cmd.contains("antigravity") {
                isRunning = true
                pid = proc.pid
                if let modelRange = cmd.range(of: "--model ") {
                    let sub = cmd[modelRange.upperBound...]
                    let modelToken = sub.prefix(while: { !$0.isWhitespace })
                    if !modelToken.isEmpty {
                        modelName = String(modelToken)
                    }
                }
                if let dirRange = cmd.range(of: "--add-dir ") {
                    let sub = cmd[dirRange.upperBound...]
                    let dirToken = sub.prefix(while: { !$0.isWhitespace })
                    if !dirToken.isEmpty {
                        activeDirectory = String(dirToken)
                    }
                }
                break
            }
        }

        // Read last history entry from ~/.claude/history.jsonl
        var lastPrompt: String? = nil
        var lastTime: Date? = nil
        let historyPath = ("~/.claude/history.jsonl" as NSString).expandingTildeInPath
        if let lastLine = readLastLineOfFile(path: historyPath) {
            if let data = lastLine.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                lastPrompt = json["display"] as? String
                if let ts = json["timestamp"] as? Double {
                    lastTime = Date(timeIntervalSince1970: ts / 1000.0)
                }
                if activeDirectory == nil {
                    activeDirectory = json["project"] as? String
                }
            }
        }

        return AIAgentSession(
            id: "agent-claude",
            agentType: .claude,
            isRunning: isRunning,
            pid: pid,
            activeDirectory: activeDirectory,
            modelName: modelName,
            lastTaskPrompt: lastPrompt ?? "Idle session",
            lastActivityTime: lastTime ?? Date(),
            costOrTokenSummary: isRunning ? "Active Session" : "Standby"
        )
    }

    private func inspectCodexSession(processTable: [(pid: Int32, command: String)]) async -> AIAgentSession {
        var isRunning = false
        var pid: Int32? = nil

        for proc in processTable {
            let cmd = proc.command
            if cmd.contains("codex app-server") || (cmd.contains("codex") && !cmd.contains("grep") && !cmd.contains("antigravity")) {
                isRunning = true
                pid = proc.pid
                break
            }
        }

        var lastThread: String? = nil
        var lastTime: Date? = nil
        let sessionIndexPath = ("~/.codex/session_index.jsonl" as NSString).expandingTildeInPath
        if let lastLine = readLastLineOfFile(path: sessionIndexPath) {
            if let data = lastLine.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                lastThread = json["thread_name"] as? String
                if let updatedStr = json["updated_at"] as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    lastTime = formatter.date(from: updatedStr)
                }
            }
        }

        return AIAgentSession(
            id: "agent-codex",
            agentType: .codex,
            isRunning: isRunning,
            pid: pid,
            activeDirectory: nil,
            modelName: "Codex Daemon",
            lastTaskPrompt: lastThread ?? "Shared app-server",
            lastActivityTime: lastTime ?? Date(),
            costOrTokenSummary: isRunning ? "App Server LIVE" : "Ready"
        )
    }

    private func inspectOpenCodeSession(processTable: [(pid: Int32, command: String)]) async -> AIAgentSession {
        var isRunning = false
        var pid: Int32? = nil

        for proc in processTable {
            let cmd = proc.command
            if (cmd.hasPrefix("opencode ") || cmd.contains("/opencode ")) && !cmd.contains("grep") {
                isRunning = true
                pid = proc.pid
                break
            }
        }

        // Query last session from ~/.local/share/opencode/opencode.db
        var lastTitle: String? = nil
        var activeDir: String? = nil
        var modelName = "space-bunny-free"
        var lastTime: Date? = nil

        let dbPath = ("~/.local/share/opencode/opencode.db" as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: dbPath) {
            let query = "SELECT title, directory, model, time_updated FROM session ORDER BY time_updated DESC LIMIT 1;"
            let result = await runCLIProcess(
                executable: "/usr/bin/sqlite3",
                arguments: [dbPath, query],
                workingDirectory: NSHomeDirectory()
            )
            let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let columns = trimmed.components(separatedBy: "|")
                if columns.count >= 4 {
                    lastTitle = columns[0]
                    activeDir = columns[1]
                    if let modelData = columns[2].data(using: .utf8),
                       let modelJson = try? JSONSerialization.jsonObject(with: modelData) as? [String: Any],
                       let id = modelJson["id"] as? String {
                        modelName = id
                    }
                    if let ms = Double(columns[3]) {
                        lastTime = Date(timeIntervalSince1970: ms / 1000.0)
                    }
                }
            }
        }

        return AIAgentSession(
            id: "agent-opencode",
            agentType: .opencode,
            isRunning: isRunning,
            pid: pid,
            activeDirectory: activeDir,
            modelName: modelName,
            lastTaskPrompt: lastTitle ?? "OpenCode Workspace",
            lastActivityTime: lastTime ?? Date(),
            costOrTokenSummary: "SQLite Session"
        )
    }

    private func inspectOllama(processTable: [(pid: Int32, command: String)]) async -> (AIAgentSession, [OllamaLoadedModel]) {
        let serverProcess = processTable.first { $0.command.contains("ollama serve") }
        var installedModels: [String] = []
        var loadedModels: [OllamaLoadedModel] = []

        if serverProcess != nil {
            installedModels = await fetchOllamaInstalledModelNames()
            loadedModels = await fetchOllamaLoadedModels()
        }

        let session = AIAgentSession(
            id: "agent-ollama",
            agentType: .ollama,
            isRunning: serverProcess != nil,
            pid: serverProcess?.pid,
            activeDirectory: "127.0.0.1:11434",
            modelName: loadedModels.first?.name ?? installedModels.first ?? "No models installed",
            lastTaskPrompt: "\(installedModels.count) installed · \(loadedModels.count) loaded in memory",
            lastActivityTime: Date(),
            costOrTokenSummary: "100% Offline"
        )
        return (session, loadedModels)
    }

    private struct OllamaTagsResponse: Decodable {
        struct Model: Decodable {
            let name: String
        }
        let models: [Model]
    }

    private struct OllamaPSResponse: Decodable {
        struct Model: Decodable {
            let name: String
            let size: Int64
            let size_vram: Int64?
            let expires_at: String?
        }
        let models: [Model]
    }

    private func fetchOllamaInstalledModelNames() async -> [String] {
        guard let response: OllamaTagsResponse = await fetchOllamaJSON(path: "/api/tags") else {
            return []
        }
        return response.models.map(\.name)
    }

    /// `/api/ps`: şu an belleğe yüklü modeller ve kullandıkları VRAM (gerçek kaynak tüketimi).
    private func fetchOllamaLoadedModels() async -> [OllamaLoadedModel] {
        guard let response: OllamaPSResponse = await fetchOllamaJSON(path: "/api/ps") else {
            return []
        }
        let isoStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        return response.models.map { model in
            OllamaLoadedModel(
                name: model.name,
                sizeBytes: model.size,
                vramBytes: model.size_vram ?? 0,
                expiresAt: model.expires_at.flatMap { try? isoStyle.parse($0) }
            )
        }
    }

    private func fetchOllamaJSON<Response: Decodable>(path: String) async -> Response? {
        guard let url = URL(string: "http://127.0.0.1:11434\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                Logger.general.error("Ollama request failed path=\(path, privacy: .public) status=\(status, privacy: .public)")
                return nil
            }
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            Logger.general.error("Ollama request failed path=\(path, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func readLastLineOfFile(path: String) -> String? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? fileHandle.close() }

        let fileSize = fileHandle.seekToEndOfFile()
        guard fileSize > 0 else { return nil }

        let readLength = min(fileSize, UInt64(4096))
        fileHandle.seek(toFileOffset: fileSize - readLength)
        let data = fileHandle.readDataToEndOfFile()
        guard let chunk = String(data: data, encoding: .utf8) else { return nil }

        let lines = chunk.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lines.last
    }

    private func runCLIProcess(
        executable: String,
        arguments: [String],
        workingDirectory: String
    ) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    guard process.terminationStatus == 0 else {
                        continuation.resume(returning: "Process \((executable as NSString).lastPathComponent) exited with status \(process.terminationStatus):\n\(output)")
                        return
                    }
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(returning: "Execution error: \(error.localizedDescription)")
                }
            }
        }
    }

    /// GUI uygulamaları kabuk PATH'ini miras almadığından yaygın CLI kurulum dizinlerini de tarar.
    private func resolveExecutable(named name: String) -> String? {
        let pathDirectories: [String] = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        let wellKnownDirectories: [String] = [
            ("~/.local/bin" as NSString).expandingTildeInPath,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin"
        ]
        return (wellKnownDirectories + pathDirectories)
            .map { ($0 as NSString).appendingPathComponent(name) }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func missingExecutableMessage(name: String) -> String {
        "'\(name)' CLI was not found in ~/.local/bin, /opt/homebrew/bin, /usr/local/bin or PATH. Install it or add it to one of these locations."
    }

    private func trimmedTokenEstimate(prompt: String) -> Int {
        max(1, prompt.count / 4)
    }
}
