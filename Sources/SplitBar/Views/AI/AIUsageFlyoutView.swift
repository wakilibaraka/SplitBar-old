import SwiftUI

public enum AIUsageTab: Int, CaseIterable, Sendable {
    case limits
    case agents
    case dispatch
    case usage

    public var title: String {
        switch self {
        case .limits: return "Limits"
        case .agents: return "Agents"
        case .dispatch: return "Dispatch"
        case .usage: return "Usage"
        }
    }
}

public struct AIUsageFlyoutView: View {
    public let state: AIUsageState
    public let onRefresh: () -> Void
    public let onDispatchTask: (AIAgentType, String, Bool) async -> String
    public let onSwitchAccount: (AIAccount) -> Void
    public let onRemoveAccount: (AIAccount) -> Void
    public let onAddAccount: (AIAccountProvider) -> Void
    public let onReloginAccount: (AIAccount) -> Void
    public let onConnectClaudeLimits: () -> Void
    public let onDisconnectClaudeLimits: () -> Void

    // Sekme ve görev metni görünümün kendi durumudur: flyout canlı güncellemelerde yerinde yenilendiği için
    // korunur ve tıklama anında yansır (controller üzerinden closure bağlaması SwiftUI'ye değişikliği bildirmez)
    @State private var selectedTab: AIUsageTab = .limits
    @State private var taskPrompt: String = ""
    @State private var selectedAgent: AIAgentType = .claude
    @State private var isExecuting: Bool = false
    @State private var taskOutput: String = ""
    @State private var lastRunDuration: TimeInterval?

    public init(
        state: AIUsageState,
        onRefresh: @escaping () -> Void,
        onDispatchTask: @escaping (AIAgentType, String, Bool) async -> String,
        onSwitchAccount: @escaping (AIAccount) -> Void,
        onRemoveAccount: @escaping (AIAccount) -> Void,
        onAddAccount: @escaping (AIAccountProvider) -> Void,
        onReloginAccount: @escaping (AIAccount) -> Void,
        onConnectClaudeLimits: @escaping () -> Void,
        onDisconnectClaudeLimits: @escaping () -> Void
    ) {
        self.state = state
        self.onRefresh = onRefresh
        self.onDispatchTask = onDispatchTask
        self.onSwitchAccount = onSwitchAccount
        self.onRemoveAccount = onRemoveAccount
        self.onAddAccount = onAddAccount
        self.onReloginAccount = onReloginAccount
        self.onConnectClaudeLimits = onConnectClaudeLimits
        self.onDisconnectClaudeLimits = onDisconnectClaudeLimits
    }

    public var body: some View {
        VStack(spacing: 12.0) {
            // Header with Real-Time Indicator & Refresh
            HStack {
                HStack(spacing: 7.0) {
                    Circle()
                        .fill(state.hasRunningAgent ? Color(red: 0.20, green: 0.90, blue: 0.50) : Color.primary.opacity(0.35))
                        .frame(width: 7.0, height: 7.0)
                        .shadow(
                            color: state.hasRunningAgent ? Color(red: 0.20, green: 0.90, blue: 0.50).opacity(0.80) : Color.clear,
                            radius: 4.0
                        )

                    Text(state.hasRunningAgent ? "Live AI Processes Active" : "AI Hub Ready")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityLabel("Refresh AI Usage")
                        .font(.system(size: 11.0, weight: .semibold))
                        .foregroundColor(Color.primary.opacity(0.70))
                        .frame(width: 22.0, height: 22.0)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            .padding(.horizontal, 4.0)

            // Navigation Segmented Control (Noir Liquid Glass)
            HStack(spacing: 4.0) {
                ForEach(AIUsageTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(3.0)
            .background(
                RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.75)
                    )
            )

            // Content Area
            switch selectedTab {
            case .limits:
                limitsTab
            case .agents:
                agentsTab
            case .dispatch:
                dispatchTab
            case .usage:
                usageTab
            }

            Divider()
                .overlay(Color.primary.opacity(0.12))

            // Footer
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 10.0))
                    .foregroundColor(Color.primary.opacity(0.45))
                Text("Local telemetry · plan limits from Claude Code & Codex")
                    .font(.system(size: 10.0))
                    .foregroundColor(Color.primary.opacity(0.50))
                Spacer()
                Text(state.lastUpdated == .distantPast ? "Loading" : "Updated \(state.lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 9.0, weight: .bold))
                    .foregroundColor(Color.primary.opacity(0.50))
            }
            .padding(.horizontal, 4.0)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tabs

    private func tabButton(_ tab: AIUsageTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        }) {
            Text(tab.title)
                .font(.system(size: 11.0, weight: selectedTab == tab ? .semibold : .regular))
                .foregroundColor(selectedTab == tab ? .primary : Color.primary.opacity(0.55))
                .padding(.vertical, 5.0)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                                .fill(Color.primary.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.25), lineWidth: 0.75)
                                )
                                .shadow(color: Color.black.opacity(0.30), radius: 3.0, x: 0.0, y: 1.0)
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    private var agentsTab: some View {
        ScrollView {
            VStack(spacing: 8.0) {
                ForEach(state.agentSessions) { session in
                    agentSessionCard(session: session)
                }
            }
            .padding(.vertical, 2.0)
        }
        .frame(maxHeight: 480.0)
    }

    private func agentSessionCard(session: AIAgentSession) -> some View {
        VStack(alignment: .leading, spacing: 7.0) {
            HStack(spacing: 10.0) {
                // Real Vector Brand Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                        .fill(Color.primary.opacity(session.isRunning ? 0.12 : 0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                                .strokeBorder(Color.primary.opacity(session.isRunning ? 0.25 : 0.10), lineWidth: 0.75)
                        )
                        .frame(width: 32.0, height: 32.0)

                    AILogoView(
                        agentType: session.agentType,
                        size: 18.0,
                        isMonochrome: false
                    )
                }

                VStack(alignment: .leading, spacing: 2.0) {
                    HStack(spacing: 6.0) {
                        Text(session.agentType.rawValue)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(.primary)

                        if session.isRunning {
                            HStack(spacing: 3.0) {
                                Circle()
                                    .fill(Color(red: 0.20, green: 0.90, blue: 0.50))
                                    .frame(width: 4.5, height: 4.5)
                                Text(session.pid.map { "PID \(String($0))" } ?? "LIVE")
                                    .font(.system(size: 9.0, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 6.0)
                            .padding(.vertical, 2.0)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.12))
                                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.20), lineWidth: 0.75))
                            )
                        } else {
                            Text("STANDBY")
                                .font(.system(size: 9.0, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.primary.opacity(0.45))
                                .padding(.horizontal, 5.0)
                                .padding(.vertical, 2.0)
                                .background(
                                    Capsule()
                                        .fill(Color.primary.opacity(0.06))
                                )
                        }
                    }

                    Text(session.modelName)
                        .font(.system(size: 10.0, design: .monospaced))
                        .foregroundColor(Color.primary.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    selectedAgent = session.agentType
                    selectedTab = .dispatch
                }) {
                    Text("Dispatch")
                        .font(.system(size: 10.5, weight: .semibold))
                        .padding(.horizontal, 10.0)
                        .padding(.vertical, 4.0)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.12))
                                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.24), lineWidth: 0.75))
                        )
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }

            if let prompt = session.lastTaskPrompt, !prompt.isEmpty {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text("Last Session / Turn:")
                        .font(.system(size: 9.0, weight: .semibold))
                        .foregroundColor(Color.primary.opacity(0.50))

                    Text(prompt)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(Color.primary.opacity(0.90))
                        .lineLimit(2)
                }
                .padding(7.0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .liquidGlassWell(cornerRadius: 8.0)
            }

            if let dir = session.activeDirectory, !dir.isEmpty {
                HStack(spacing: 5.0) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 9.0))
                        .foregroundColor(Color.primary.opacity(0.40))
                    Text(dir)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(Color.primary.opacity(0.50))
                        .lineLimit(1)
                }
            }
        }
        .padding(11.0)
        .background(
            RoundedRectangle(cornerRadius: 14.0, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14.0, style: .continuous)
                        .strokeBorder(
                            session.isRunning
                                ? LinearGradient(
                                    stops: [
                                        .init(color: Color.primary.opacity(0.40), location: 0.0),
                                        .init(color: Color.primary.opacity(0.10), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    stops: [
                                        .init(color: Color.primary.opacity(0.12), location: 0.0),
                                        .init(color: Color.primary.opacity(0.04), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: 0.75
                        )
                )
        )
    }

    // MARK: - Dispatch

    private func accentColor(for agent: AIAgentType) -> Color {
        switch agent {
        case .claude:
            return providerBrandColor(.claude)
        case .codex:
            return providerBrandColor(.codex)
        case .opencode:
            return SplitBarPalette.violet
        case .ollama:
            return SplitBarPalette.silver
        }
    }

    private func shortName(for agent: AIAgentType) -> String {
        switch agent {
        case .claude:
            return "Claude Code"
        case .codex:
            return "Codex"
        case .opencode:
            return "OpenCode"
        case .ollama:
            return "Ollama"
        }
    }

    private func session(for agent: AIAgentType) -> AIAgentSession? {
        state.agentSessions.first { $0.agentType == agent }
    }

    private var dispatchTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12.0) {
                agentPicker
                composer
                if isExecuting || !taskOutput.isEmpty {
                    responseCard
                } else {
                    dispatchHint
                }
            }
            .padding(.vertical, 2.0)
        }
        .frame(maxHeight: 480.0)
    }

    private var agentPicker: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8.0), GridItem(.flexible(), spacing: 8.0)], spacing: 8.0) {
            ForEach(AIAgentType.allCases, id: \.self) { agent in
                agentCard(agent)
            }
        }
    }

    private func agentCard(_ agent: AIAgentType) -> some View {
        let isSelected = selectedAgent == agent
        let accent = accentColor(for: agent)
        let agentSession = session(for: agent)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedAgent = agent
            }
        } label: {
            HStack(spacing: 9.0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                        .fill(accent.opacity(isSelected ? 0.22 : 0.10))
                        .frame(width: 30.0, height: 30.0)
                    AILogoView(agentType: agent, size: 16.0, isMonochrome: false)
                }
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(shortName(for: agent))
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.primary)
                    HStack(spacing: 4.0) {
                        Circle()
                            .fill(agentSession?.isRunning == true ? limitSeverityColor(percent: 0.0) : Color.secondary.opacity(0.5))
                            .frame(width: 5.0, height: 5.0)
                        Text(agentSession?.modelName ?? "Not detected")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 0.0)
            }
            .padding(.horizontal, 10.0)
            .padding(.vertical, 8.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11.0, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.10) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11.0, style: .continuous)
                    .strokeBorder(isSelected ? accent.opacity(0.75) : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.2 : 0.75)
            )
            .contentShape(RoundedRectangle(cornerRadius: 11.0, style: .continuous))
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .accessibilityLabel("\(shortName(for: agent))\(isSelected ? ", selected" : "")")
    }

    private var composer: some View {
        let accent = accentColor(for: selectedAgent)
        return VStack(alignment: .leading, spacing: 0.0) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $taskPrompt)
                    .font(.system(size: 12.0))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96.0, maxHeight: 140.0)
                    .padding(.horizontal, 6.0)
                    .padding(.top, 8.0)

                if taskPrompt.isEmpty {
                    Text("Describe a task for \(shortName(for: selectedAgent))…")
                        .font(.system(size: 12.0))
                        .foregroundColor(Color.primary.opacity(0.38))
                        .padding(.leading, 11.0)
                        .padding(.top, 8.0)
                        .allowsHitTesting(false)
                }
            }

            Divider()
                .opacity(0.4)

            HStack(spacing: 8.0) {
                if let directory = session(for: selectedAgent)?.activeDirectory, !directory.isEmpty {
                    Label((directory as NSString).abbreviatingWithTildeInPath, systemImage: "folder")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                } else {
                    Text("⌘↩ to run")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 4.0)

                Button {
                    executeTask(openTerminal: true)
                } label: {
                    Image(systemName: "terminal")
                        .font(.system(size: 11.0, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 28.0, height: 28.0)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .disabled(isRunDisabled)
                .opacity(isRunDisabled ? 0.4 : 1.0)
                .help("Open an interactive \(shortName(for: selectedAgent)) session in Terminal")
                .accessibilityLabel("Open in Terminal")
                .pointingHandCursor()

                Button {
                    executeTask(openTerminal: false)
                } label: {
                    HStack(spacing: 5.0) {
                        if isExecuting {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                                .frame(width: 12.0, height: 12.0)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 11.0, weight: .bold))
                        }
                        Text(isExecuting ? "Running" : "Run")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12.0)
                    .frame(height: 28.0)
                    .background(Capsule().fill(accent))
                    .shadow(color: accent.opacity(0.45), radius: 6.0, x: 0.0, y: 2.0)
                }
                .buttonStyle(.plain)
                .disabled(isRunDisabled)
                .opacity(isRunDisabled ? 0.45 : 1.0)
                .keyboardShortcut(.return, modifiers: .command)
                .help("Run and show the result here (⌘↩)")
                .pointingHandCursor()
            }
            .padding(.horizontal, 10.0)
            .padding(.vertical, 8.0)
        }
        .liquidGlassWell(cornerRadius: 12.0)
    }

    private var dispatchHint: some View {
        HStack(alignment: .top, spacing: 8.0) {
            Image(systemName: "sparkles")
                .font(.system(size: 12.0))
                .foregroundColor(accentColor(for: selectedAgent))
            Text("Run sends the task to \(shortName(for: selectedAgent)) headlessly and shows the answer here. The terminal button opens a full interactive session instead.")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4.0)
    }

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            HStack(spacing: 7.0) {
                AILogoView(agentType: selectedAgent, size: 13.0, isMonochrome: false)
                Text(shortName(for: selectedAgent))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.primary)
                if isExecuting {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.6)
                    Text("Working…")
                        .font(.system(size: 10.0))
                        .foregroundColor(.secondary)
                } else if let duration = lastRunDuration {
                    Text(String(format: "Done in %.1fs", duration))
                        .font(.system(size: 10.0))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !taskOutput.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(taskOutput, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy Result")
                    .accessibilityLabel("Copy Result")
                    .pointingHandCursor()

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            taskOutput = ""
                            lastRunDuration = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11.0))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear Result")
                    .accessibilityLabel("Clear Result")
                    .pointingHandCursor()
                }
            }

            ScrollView {
                Text(taskOutput.isEmpty ? "Waiting for \(shortName(for: selectedAgent))…" : taskOutput)
                    .font(.system(size: 11.0, design: .monospaced))
                    .foregroundColor(taskOutput.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8.0)
            }
            .frame(minHeight: 60.0, maxHeight: 200.0)
            .liquidGlassWell(cornerRadius: 9.0)
        }
        .padding(11.0)
        .liquidGlassCard(cornerRadius: 14.0, isHovered: false)
    }

    private var limitsTab: some View {
        ScrollView {
            VStack(spacing: 10.0) {
                if state.limitCards.isEmpty {
                    ProgressView("Reading accounts and plan limits…")
                        .controlSize(.small)
                        .frame(maxWidth: .infinity, minHeight: 200.0)
                }
                ForEach(state.limitCards) { card in
                    ProviderLimitCardView(
                        card: card,
                        onSwitchAccount: onSwitchAccount,
                        onRemoveAccount: onRemoveAccount,
                        onAddAccount: onAddAccount,
                        onReloginAccount: onReloginAccount,
                        onConnectLimits: onConnectClaudeLimits,
                        onDisconnectLimits: onDisconnectClaudeLimits
                    )
                }
            }
            .padding(.vertical, 2.0)
        }
        .frame(maxHeight: 480.0)
    }

    private var usageTab: some View {
        ScrollView {
            VStack(spacing: 10.0) {
                TokenUsageChartView(usage: state.dailyUsage)
                OllamaModelsView(
                    models: state.ollamaModels,
                    isServerRunning: state.agentSessions.first { $0.agentType == .ollama }?.isRunning ?? false
                )
            }
            .padding(.vertical, 2.0)
        }
        .frame(maxHeight: 480.0)
    }

    private var isRunDisabled: Bool {
        isExecuting || taskPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func executeTask(openTerminal: Bool) {
        let prompt = taskPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        isExecuting = true
        taskOutput = ""
        lastRunDuration = nil
        let startedAt = Date()

        Task {
            let output = await onDispatchTask(selectedAgent, prompt, openTerminal)
            self.taskOutput = output
            self.lastRunDuration = Date().timeIntervalSince(startedAt)
            self.isExecuting = false
        }
    }
}
