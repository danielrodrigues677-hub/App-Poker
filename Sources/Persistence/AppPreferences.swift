import Foundation
import GameEngine

/// Preferências locais (UserDefaults). Coach ligado no 1º uso.
public struct AppPreferences: Codable, Sendable, Equatable {
    public var coachEnabled: Bool
    public var tutorialCompleted: Bool
    public var preferredCashPresetId: String
    public var preferredCashBotCount: Int
    public var preferredSNGFormat: SNGFormat

    public static let `default` = AppPreferences(
        coachEnabled: true,
        tutorialCompleted: false,
        preferredCashPresetId: BlindPreset.default.id,
        preferredCashBotCount: 5,
        preferredSNGFormat: .sixMax
    )

    public init(
        coachEnabled: Bool,
        tutorialCompleted: Bool,
        preferredCashPresetId: String,
        preferredCashBotCount: Int,
        preferredSNGFormat: SNGFormat
    ) {
        self.coachEnabled = coachEnabled
        self.tutorialCompleted = tutorialCompleted
        self.preferredCashPresetId = preferredCashPresetId
        self.preferredCashBotCount = preferredCashBotCount
        self.preferredSNGFormat = preferredSNGFormat
    }
}

public struct SessionSummary: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public let kind: String // "cash" | "sng"
    public let finishedAt: Date
    public let detailPT: String
    public let handsPlayed: Int

    public init(id: String = UUID().uuidString, kind: String, finishedAt: Date = Date(), detailPT: String, handsPlayed: Int) {
        self.id = id
        self.kind = kind
        self.finishedAt = finishedAt
        self.detailPT = detailPT
        self.handsPlayed = handsPlayed
    }
}

public protocol KeyValueStore: Sendable {
    func data(forKey key: String) -> Data?
    func set(_ data: Data?, forKey key: String)
}

public final class UserDefaultsStore: KeyValueStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    public func set(_ data: Data?, forKey key: String) {
        defaults.set(data, forKey: key)
    }
}

/// Store em memória para testes.
public final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    public init() {}

    public func data(forKey key: String) -> Data? {
        storage[key]
    }

    public func set(_ data: Data?, forKey key: String) {
        if let data {
            storage[key] = data
        } else {
            storage.removeValue(forKey: key)
        }
    }
}

public final class LocalPersistence: @unchecked Sendable {
    public static let shared = LocalPersistence()

    private let store: KeyValueStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let preferences = "apppoker.preferences"
        static let sessions = "apppoker.sessions"
        static let lastReplay = "apppoker.lastReplay"
    }

    public init(store: KeyValueStore = UserDefaultsStore()) {
        self.store = store
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: Preferências

    public func loadPreferences() -> AppPreferences {
        guard let data = store.data(forKey: Keys.preferences),
              let prefs = try? decoder.decode(AppPreferences.self, from: data)
        else {
            let fresh = AppPreferences.default
            savePreferences(fresh)
            return fresh
        }
        return prefs
    }

    public func savePreferences(_ prefs: AppPreferences) {
        if let data = try? encoder.encode(prefs) {
            store.set(data, forKey: Keys.preferences)
        }
    }

    public func updatePreferences(_ mutate: (inout AppPreferences) -> Void) {
        var prefs = loadPreferences()
        mutate(&prefs)
        savePreferences(prefs)
    }

    // MARK: Sessões

    public func loadSessions() -> [SessionSummary] {
        guard let data = store.data(forKey: Keys.sessions),
              let list = try? decoder.decode([SessionSummary].self, from: data)
        else { return [] }
        return list
    }

    public func appendSession(_ summary: SessionSummary, limit: Int = 20) {
        var list = loadSessions()
        list.insert(summary, at: 0)
        if list.count > limit {
            list = Array(list.prefix(limit))
        }
        if let data = try? encoder.encode(list) {
            store.set(data, forKey: Keys.sessions)
        }
    }

    // MARK: Replay

    public func loadLastReplay() -> HandReplay? {
        guard let data = store.data(forKey: Keys.lastReplay) else { return nil }
        return try? decoder.decode(HandReplay.self, from: data)
    }

    public func saveLastReplay(_ replay: HandReplay?) {
        guard let replay else {
            store.set(nil, forKey: Keys.lastReplay)
            return
        }
        if let data = try? encoder.encode(replay) {
            store.set(data, forKey: Keys.lastReplay)
        }
    }
}
