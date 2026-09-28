import Charts
import SwiftUI

// MARK: - Formatting

/// Kalan süreyi "2h 14m", "3d 4h" veya "45m" biçiminde gösterir.
public func formatResetCountdown(resetsAt: Date, now: Date) -> String {
    let remaining = max(0, Int(resetsAt.timeIntervalSince(now)))
    let days = remaining / 86_400
    let hours = (remaining % 86_400) / 3_600
    let minutes = (remaining % 3_600) / 60
    if days > 0 {
        return "\(days)d \(hours)h"
    }
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }
    return "\(max(minutes, 1))m"
}

/// Geçen süreyi arayüz diliyle tutarlı biçimde "just now", "5m ago", "8h ago", "2d ago" olarak gösterir.
public func formatElapsed(since date: Date, now: Date) -> String {
    let elapsed = max(0, Int(now.timeIntervalSince(date)))
    if elapsed < 60 {
        return "just now"
    }
    if elapsed < 3_600 {
        return "\(elapsed / 60)m ago"
    }
    if elapsed < 86_400 {
        return "\(elapsed / 3_600)h ago"
    }
    return "\(elapsed / 86_400)d ago"
}

/// Token sayısını "842", "12.4K", "3.1M" gibi kısa biçimde gösterir.
public func formatTokenCount(_ tokens: Int) -> String {
    let value = Double(tokens)
    if value >= 1_000_000_000 {
        return String(format: "%.1fB", value / 1_000_000_000)
    }
    if value >= 1_000_000 {
        return String(format: "%.1fM", value / 1_000_000)
    }
    if value >= 1_000 {
        return String(format: "%.1fK", value / 1_000)
    }
    return "\(tokens)"
}

/// Limit doluluğuna göre durum rengi: rahat, dikkat, kritik.
public func limitSeverityColor(percent: Double) -> Color {
    if percent >= 85.0 {
        return SplitBarPalette.coral
    }
    if percent >= 60.0 {
        return SplitBarPalette.amber
    }
    return SplitBarPalette.mint
}

public func providerBrandColor(_ provider: AIAccountProvider) -> Color {
    switch provider {
    case .claude:
        return SplitBarPalette.terracotta
    case .codex:
        return SplitBarPalette.cyan
    }
}

private func windowLabel(minutes: Int) -> String {
    if minutes >= 10_080 {
        return "Weekly"
    }
    if minutes >= 60 {
        return "\(minutes / 60)-hour"
    }
    return "\(minutes)-min"
}

// MARK: - Ring gauge

/// Tek bir limit penceresi için halka gösterge. Sağlayıcıların kendi arayüzleri gibi kalan kotayı gösterir;
/// renk kullanım arttıkça yeşilden turuncuya ve kırmızıya döner.
public struct UsageRingView: View {
    public let window: UsageWindow?
    public let fallbackTitle: String
    public let now: Date

    public init(window: UsageWindow?, fallbackTitle: String, now: Date) {
        self.window = window
        self.fallbackTitle = fallbackTitle
        self.now = now
    }

    private var usedPercent: Double? {
        window.map { effectiveUsedPercent(window: $0, now: now) }
    }

    private var remainingPercent: Double? {
        usedPercent.map { 100.0 - $0 }
    }

    private var title: String {
        window.map { windowLabel(minutes: $0.windowMinutes) } ?? fallbackTitle
    }

    private var resetText: String {
        guard let resetsAt = window?.resetsAt else {
            return "No reset data"
        }
        if resetsAt <= now {
            return "Window reset"
        }
        return "Resets in \(formatResetCountdown(resetsAt: resetsAt, now: now))"
    }

    public var body: some View {
        let fraction = (remainingPercent ?? 0.0) / 100.0
        let color = limitSeverityColor(percent: usedPercent ?? 0.0)

        VStack(spacing: 6.0) {
            GaugeRingView(
                fraction: fraction,
                tint: color,
                valueText: remainingPercent.map { "\(Int($0.rounded()))%" } ?? "—",
                captionText: "left",
                diameter: 84.0
            )

            Text(title)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(.primary)

            Text(resetText)
                .font(.system(size: 10.0, weight: .medium))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) limit, \(remainingPercent.map { "\(Int($0.rounded())) percent left" } ?? "unknown"), \(resetText)")
    }
}

// MARK: - Provider card

public struct ProviderLimitCardView: View {
    public let card: ProviderLimitCard
    public let onSwitchAccount: (AIAccount) -> Void
    public let onRemoveAccount: (AIAccount) -> Void
    public let onAddAccount: (AIAccountProvider) -> Void
    public let onReloginAccount: (AIAccount) -> Void
    public let onConnectLimits: () -> Void
    public let onDisconnectLimits: () -> Void

    public init(
        card: ProviderLimitCard,
        onSwitchAccount: @escaping (AIAccount) -> Void,
        onRemoveAccount: @escaping (AIAccount) -> Void,
        onAddAccount: @escaping (AIAccountProvider) -> Void,
        onReloginAccount: @escaping (AIAccount) -> Void,
        onConnectLimits: @escaping () -> Void,
        onDisconnectLimits: @escaping () -> Void
    ) {
        self.card = card
        self.onSwitchAccount = onSwitchAccount
        self.onRemoveAccount = onRemoveAccount
        self.onAddAccount = onAddAccount
        self.onReloginAccount = onReloginAccount
        self.onConnectLimits = onConnectLimits
        self.onDisconnectLimits = onDisconnectLimits
    }

    public var body: some View {
        // Geri sayımlar flyout yenilenmese de periyodik olarak güncellenir
        TimelineView(.periodic(from: .now, by: 30.0)) { context in
            VStack(alignment: .leading, spacing: 12.0) {
                header
                content(now: context.date)
            }
            .padding(12.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassCard(cornerRadius: 14.0, isHovered: false)
        }
    }

    private var brandColor: Color {
        providerBrandColor(card.provider)
    }

    private var header: some View {
        HStack(spacing: 10.0) {
            ZStack {
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .fill(brandColor.opacity(0.14))
                    .frame(width: 32.0, height: 32.0)
                AILogoView(agentType: card.provider.agentType, size: 18.0, isMonochrome: false)
            }

            VStack(alignment: .leading, spacing: 2.0) {
                HStack(spacing: 6.0) {
                    Text(card.provider.displayName)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.primary)
                    if let plan = card.activeAccount?.planName {
                        Text(plan)
                            .font(.system(size: 9.0, weight: .bold))
                            .foregroundColor(brandColor)
                            .padding(.horizontal, 6.0)
                            .padding(.vertical, 1.5)
                            .liquidGlassPill(accentColor: brandColor)
                    }
                }
                accountMenu
            }

            Spacer(minLength: 4.0)

            if card.isProviderRunning {
                HStack(spacing: 4.0) {
                    Circle()
                        .fill(limitSeverityColor(percent: 0.0))
                        .frame(width: 6.0, height: 6.0)
                    Text("LIVE")
                        .font(.system(size: 9.0, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var removableAccounts: [AIAccount] {
        card.savedAccounts.filter { $0.id != card.activeAccount?.id }
    }

    private var accountMenu: some View {
        Menu {
            Section("Saved Accounts") {
                ForEach(card.savedAccounts) { account in
                    Button {
                        // Kayıtlı girişi kullanılamayan hesaba geçilemez; doğrudan o hesapla yeniden giriş açılır
                        if card.accountsNeedingLogin.contains(account.id) {
                            onReloginAccount(account)
                        } else {
                            onSwitchAccount(account)
                        }
                    } label: {
                        if account.id == card.activeAccount?.id {
                            Label(accountMenuTitle(account), systemImage: "checkmark")
                        } else {
                            Text(accountMenuTitle(account))
                        }
                    }
                    .disabled(account.id == card.activeAccount?.id)
                }
            }
            Divider()
            Button("Log In to Another Account…") {
                onAddAccount(card.provider)
            }
            if card.provider == .claude && card.isLimitSourceConnected {
                Button("Disconnect Limit Bridge…", action: onDisconnectLimits)
            }
            if !removableAccounts.isEmpty {
                Menu("Remove Saved Account") {
                    ForEach(removableAccounts) { account in
                        Button(account.email, role: .destructive) {
                            onRemoveAccount(account)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 3.0) {
                Text(card.activeAccount?.email ?? "Not logged in")
                    .font(.system(size: 10.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 7.5, weight: .semibold))
            }
            .foregroundColor(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .pointingHandCursor()
        .help("Switch \(card.provider.displayName) account")
    }

    /// Menüde her hesabın son bilinen kotası da gösterilir; hangi hesaba geçileceği buna göre seçilebilir.
    private func accountMenuTitle(_ account: AIAccount) -> String {
        if card.accountsNeedingLogin.contains(account.id) {
            return "\(account.email)  ·  login required"
        }
        guard let limits = card.savedAccountLimits[account.id] else {
            return account.email
        }
        let now = Date()
        let parts = [
            limits.fiveHour.map { "5h \(Int((100.0 - effectiveUsedPercent(window: $0, now: now)).rounded()))% left" },
            limits.weekly.map { "wk \(Int((100.0 - effectiveUsedPercent(window: $0, now: now)).rounded()))% left" }
        ].compactMap { $0 }
        return parts.isEmpty ? account.email : "\(account.email)  ·  \(parts.joined(separator: " · "))"
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let issue = card.loginIssue {
            messageRow(
                icon: "exclamationmark.triangle.fill",
                text: issue,
                actionTitle: card.activeAccount == nil ? nil : "Log In Again",
                action: {
                    if let account = card.activeAccount {
                        onReloginAccount(account)
                    }
                }
            )
        }
        if let limits = card.limits {
            HStack(spacing: 0.0) {
                Spacer()
                UsageRingView(window: limits.fiveHour, fallbackTitle: "5-hour", now: now)
                Spacer()
                UsageRingView(window: limits.weekly, fallbackTitle: "Weekly", now: now)
                Spacer()
            }
            Text("Updated \(formatElapsed(since: limits.capturedAt, now: now))")
                .font(.system(size: 9.5))
                .foregroundColor(.secondary.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
        } else if card.activeAccount == nil {
            messageRow(
                icon: "person.crop.circle.badge.questionmark",
                text: "No \(card.provider.displayName) account is logged in on this Mac.",
                actionTitle: "Log In",
                action: { onAddAccount(card.provider) }
            )
        } else if !card.isLimitSourceConnected {
            messageRow(
                icon: "link.badge.plus",
                text: "Claude Code reports official plan limits only to its status line. Connect SplitBar to read them; your current status line keeps working.",
                actionTitle: "Connect",
                action: onConnectLimits
            )
        } else {
            messageRow(
                icon: "hourglass",
                text: "Limits appear after your next \(card.provider.displayName) message on this account.",
                actionTitle: nil,
                action: {}
            )
        }
    }

    private func messageRow(icon: String, text: String, actionTitle: String?, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 8.0) {
            Image(systemName: icon)
                .font(.system(size: 13.0))
                .foregroundColor(brandColor)
            Text(text)
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4.0)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                    .tint(brandColor)
                    .pointingHandCursor()
            }
        }
    }
}

// MARK: - Token history chart

public struct TokenUsageChartView: View {
    public let usage: [DailyTokenUsage]

    public init(usage: [DailyTokenUsage]) {
        self.usage = usage
    }

    public var body: some View {
        let total = usage.reduce(0) { $0 + $1.tokens }
        VStack(alignment: .leading, spacing: 8.0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Last 7 Days")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(formatTokenCount(total)) tokens")
                    .font(.system(size: 11.0, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }

            if usage.isEmpty {
                Text("Scanning local Claude Code and Codex transcripts…")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 110.0)
            } else {
                Chart(usage) { item in
                    BarMark(
                        x: .value("Day", item.day, unit: .day),
                        y: .value("Tokens", item.tokens)
                    )
                    .foregroundStyle(by: .value("Provider", item.provider.displayName))
                    .cornerRadius(3.0)
                }
                .chartForegroundStyleScale([
                    AIAccountProvider.claude.displayName: providerBrandColor(.claude),
                    AIAccountProvider.codex.displayName: providerBrandColor(.codex)
                ])
                .chartLegend(position: .bottom, spacing: 6.0)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated).locale(Locale(identifier: "en_US")), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.primary.opacity(0.08))
                        AxisValueLabel {
                            if let tokens = value.as(Int.self) {
                                Text(formatTokenCount(tokens))
                            }
                        }
                    }
                }
                .frame(height: 130.0)
            }

            Text("Includes prompt-cache tokens, read from local transcripts.")
                .font(.system(size: 9.0))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(12.0)
        .liquidGlassCard(cornerRadius: 14.0, isHovered: false)
    }
}

// MARK: - Ollama

public struct OllamaModelsView: View {
    public let models: [OllamaLoadedModel]
    public let isServerRunning: Bool

    public init(models: [OllamaLoadedModel], isServerRunning: Bool) {
        self.models = models
        self.isServerRunning = isServerRunning
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            HStack(spacing: 6.0) {
                AILogoView(agentType: .ollama, size: 13.0, isMonochrome: false)
                Text("Ollama · In Memory")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(isServerRunning ? "No limits · on-device" : "Server not running")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }
            if models.isEmpty {
                Text(isServerRunning ? "No model is loaded right now." : "Start Ollama to see loaded models.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            } else {
                ForEach(models) { model in
                    HStack {
                        Text(model.name)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: model.vramBytes, countStyle: .memory) + " VRAM")
                            .font(.system(size: 10.0, weight: .medium))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12.0)
        .liquidGlassCard(cornerRadius: 14.0, isHovered: false)
    }
}
