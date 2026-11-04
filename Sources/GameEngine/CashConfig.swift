import Foundation

/// Presets travados do MVP: blinds e buy-in = 100 BB.
public struct BlindPreset: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let smallBlind: Int
    public let bigBlind: Int

    public var buyIn: Int { bigBlind * 100 }

    public var rotuloPT: String {
        "\(smallBlind)/\(bigBlind) · buy-in \(buyIn)"
    }

    public static let all: [BlindPreset] = [
        BlindPreset(id: "1-2", smallBlind: 1, bigBlind: 2),
        BlindPreset(id: "2-5", smallBlind: 2, bigBlind: 5),
        BlindPreset(id: "5-10", smallBlind: 5, bigBlind: 10),
    ]

    public static let `default` = all[0]
}

public struct CashConfig: Codable, Sendable, Equatable {
    public var preset: BlindPreset
    /// Número de bots (oponentes). Total de assentos = bots + 1 (humano), máx 10.
    public var botCount: Int

    public var seatCount: Int { botCount + 1 }

    public init(preset: BlindPreset = .default, botCount: Int = 5) {
        self.preset = preset
        self.botCount = min(9, max(1, botCount))
    }
}
