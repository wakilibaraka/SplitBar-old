import Foundation
import OSLog

/// Claude Code ve Codex'in yerel oturum kayıtlarından gerçek limitleri ve token tüketimini okur.
/// Dosyalar yalnızca eklemeli yazıldığı için her dosyanın okunduğu konum saklanır ve sonraki
/// taramalarda yalnızca yeni satırlar işlenir.
public actor ProviderUsageScanner {
    private struct FileTokenState {
        var offset: UInt64
        var tokensByDay: [Date: Int]
        var seenKeys: Set<String>
    }

    private struct CodexLimitFileState {
        let modificationDate: Date
        let size: UInt64
        let snapshot: ProviderLimitSnapshot?
    }

    private struct RecentFile {
        let url: URL
        let modificationDate: Date
        let size: UInt64
    }

    private let claudeProjectsURL: URL
    private let codexSessionsURL: URL
    private let claudeCaptureURL: URL
    private let t3CachesURL: URL
    private var claudeFiles: [String: FileTokenState] = [:]
    private var codexFiles: [String: FileTokenState] = [:]
    private var codexLimitFiles: [String: CodexLimitFileState] = [:]

    public init(homeDirectory: URL, claudeCaptureURL: URL) {
        self.claudeProjectsURL = homeDirectory.appendingPathComponent(".claude/projects")
        self.codexSessionsURL = homeDirectory.appendingPathComponent(".codex/sessions")
        self.claudeCaptureURL = claudeCaptureURL
        self.t3CachesURL = homeDirectory.appendingPathComponent(".t3/caches")
    }

    /// T3 Code önbelleklerinden e-posta (küçük harf) başına en güncel limitler. T3 kurulu değilse boş döner.
    public func latestT3LimitsByEmail(provider: AIAccountProvider) -> [String: ProviderLimitSnapshot] {
        var result: [String: ProviderLimitSnapshot] = [:]
        for url in t3CacheFiles(provider: provider) {
            do {
                guard let scoped = try parseT3UsageCache(Data(contentsOf: url), provider: provider, source: url.path) else { continue }
                let key = scoped.email.lowercased()
                if let existing = result[key], existing.capturedAt >= scoped.snapshot.capturedAt {
                    continue
                }
                result[key] = scoped.snapshot
            } catch {
                Logger.general.error("T3 usage cache unreadable path=\(url.path, privacy: .public) error=\(String(describing: error), privacy: .public)")
            }
        }
        return result
    }

    public func hasT3Cache(provider: AIAccountProvider) -> Bool {
        !t3CacheFiles(provider: provider).isEmpty
    }

    private func t3CacheFiles(provider: AIAccountProvider) -> [URL] {
        let prefix: String
        switch provider {
        case .claude:
            prefix = "claudeAgent"
        case .codex:
            prefix = "codex"
        }
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: t3CachesURL.path) else {
            return []
        }
        return names
            .filter { $0.hasPrefix(prefix) && $0.hasSuffix(".json") }
            .map { t3CachesURL.appendingPathComponent($0) }
    }

    // MARK: - Limits

    /// Son 8 gündeki Codex oturumlarından her hesabın en güncel limit kaydını döndürür.
    public func latestCodexLimitsByAccount(now: Date) -> [String: ProviderLimitSnapshot] {
        let files = recentFiles(under: codexSessionsURL, maxAge: 8 * 86_400, now: now) { $0.hasPrefix("rollout-") }
        // Önbellek yalnızca güncel dosyalarla sınırlı tutulur; eski oturumlar birikmez
        let livePaths = Set(files.map(\.url.path))
        codexLimitFiles = codexLimitFiles.filter { livePaths.contains($0.key) }
        var result: [String: ProviderLimitSnapshot] = [:]
        for file in files {
            let snapshot: ProviderLimitSnapshot?
            if let cached = codexLimitFiles[file.url.path], cached.modificationDate == file.modificationDate, cached.size == file.size {
                snapshot = cached.snapshot
            } else {
                snapshot = latestCodexLimit(in: file.url)
                codexLimitFiles[file.url.path] = CodexLimitFileState(
                    modificationDate: file.modificationDate,
                    size: file.size,
                    snapshot: snapshot
                )
            }
            guard let snapshot, let accountID = snapshot.accountID else { continue }
            if let existing = result[accountID], existing.capturedAt >= snapshot.capturedAt {
                continue
            }
            result[accountID] = snapshot
        }
        return result
    }

    /// Status line köprüsünün yakaladığı son Claude verisi; köprü kurulu değilse veya Claude
    /// limit göndermediyse `nil` döner.
    public func latestClaudeLimits() throws -> ProviderLimitSnapshot? {
        guard FileManager.default.fileExists(atPath: claudeCaptureURL.path) else {
            return nil
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: claudeCaptureURL.path)
        guard let capturedAt = attributes[.modificationDate] as? Date else {
            throw ProviderDataParsingError.missingField(source: claudeCaptureURL.path, field: "modificationDate")
        }
        let data = try Data(contentsOf: claudeCaptureURL)
        return try parseClaudeStatusLine(data, capturedAt: capturedAt)
    }

    // MARK: - Token history

    /// Son `days` gün için sağlayıcı başına günlük token tüketimi (önbellek dahil).
    public func dailyTokenUsage(days: Int, now: Date) -> [DailyTokenUsage] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        guard let firstDay = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return []
        }
        let maxAge = now.timeIntervalSince(firstDay) + 86_400

        let claudeTotals = scanTokenFiles(
            files: recentFiles(under: claudeProjectsURL, maxAge: maxAge, now: now) { $0.hasSuffix(".jsonl") },
            previous: claudeFiles,
            parse: parseClaudeTranscriptUsage
        )
        claudeFiles = claudeTotals.cache
        let codexTotals = scanTokenFiles(
            files: recentFiles(under: codexSessionsURL, maxAge: maxAge, now: now) { $0.hasPrefix("rollout-") },
            previous: codexFiles,
            parse: parseCodexTokenUsage
        )
        codexFiles = codexTotals.cache

        return (0..<days).flatMap { offset -> [DailyTokenUsage] in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else { return [] }
            return [
                DailyTokenUsage(day: day, provider: .claude, tokens: claudeTotals.totals[day] ?? 0),
                DailyTokenUsage(day: day, provider: .codex, tokens: codexTotals.totals[day] ?? 0)
            ]
        }
    }

    // MARK: - File helpers

    private func recentFiles(under root: URL, maxAge: TimeInterval, now: Date, matching: (String) -> Bool) -> [RecentFile] {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
        guard FileManager.default.fileExists(atPath: root.path),
              let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }
        var files: [RecentFile] = []
        for case let url as URL in enumerator where matching(url.lastPathComponent) {
            let values: URLResourceValues
            do {
                values = try url.resourceValues(forKeys: Set(keys))
            } catch {
                Logger.general.error("Cannot stat transcript path=\(url.path, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
                continue
            }
            guard values.isRegularFile == true,
                  let modified = values.contentModificationDate,
                  now.timeIntervalSince(modified) <= maxAge else {
                continue
            }
            files.append(RecentFile(url: url, modificationDate: modified, size: UInt64(values.fileSize ?? 0)))
        }
        return files
    }

    private func scanTokenFiles(
        files: [RecentFile],
        previous: [String: FileTokenState],
        parse: (Substring) -> TranscriptTokenUsage?
    ) -> (totals: [Date: Int], cache: [String: FileTokenState]) {
        let calendar = Calendar.current
        var cache: [String: FileTokenState] = [:]

        for file in files {
            var state = previous[file.url.path] ?? FileTokenState(offset: 0, tokensByDay: [:], seenKeys: [])
            if file.size < state.offset {
                // Dosya kısalmış veya yeniden yazılmış: baştan oku
                state = FileTokenState(offset: 0, tokensByDay: [:], seenKeys: [])
            }
            if file.size > state.offset {
                do {
                    state = try scanAppendedLines(of: file.url, from: state, calendar: calendar, parse: parse)
                } catch {
                    Logger.general.error("Token history scan failed path=\(file.url.path, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
                }
            }
            cache[file.url.path] = state
        }

        let totals = cache.values.reduce(into: [Date: Int]()) { totals, state in
            for (day, tokens) in state.tokensByDay {
                totals[day, default: 0] += tokens
            }
        }
        return (totals: totals, cache: cache)
    }

    private func scanAppendedLines(
        of url: URL,
        from state: FileTokenState,
        calendar: Calendar,
        parse: (Substring) -> TranscriptTokenUsage?
    ) throws -> FileTokenState {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: state.offset)
        let data = try handle.readToEnd() ?? Data()
        // Yazımı süren son satır bir sonraki taramaya bırakılır
        guard let lastNewline = data.lastIndex(of: UInt8(ascii: "\n")) else {
            return state
        }
        let complete = data[data.startIndex...lastNewline]
        var updated = state
        let text = String(decoding: complete, as: UTF8.self)
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let usage = parse(line), !updated.seenKeys.contains(usage.dedupeKey) else { continue }
            updated.seenKeys.insert(usage.dedupeKey)
            updated.tokensByDay[calendar.startOfDay(for: usage.timestamp), default: 0] += usage.tokens
        }
        updated.offset += UInt64(complete.count)
        return updated
    }

    /// Dosyanın ilk satırından hesabı, son 512 KB'ından en güncel limit olayını okur.
    private func latestCodexLimit(in url: URL) -> ProviderLimitSnapshot? {
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let head = try handle.read(upToCount: 64 * 1024) ?? Data()
            let firstLine = String(decoding: head.prefix { $0 != UInt8(ascii: "\n") }, as: UTF8.self)
            let accountID = parseCodexSessionAccountID(firstLine: Substring(firstLine))

            let size = try handle.seekToEnd()
            let tailLength: UInt64 = min(size, 512 * 1024)
            try handle.seek(toOffset: size - tailLength)
            let tail = String(decoding: try handle.readToEnd() ?? Data(), as: UTF8.self)
            for line in tail.split(separator: "\n").reversed() {
                if let snapshot = parseCodexRateLimitLine(line, accountID: accountID) {
                    return snapshot
                }
            }
            return nil
        } catch {
            Logger.general.error("Codex limit scan failed path=\(url.path, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
