import Foundation

/// Um nível de blinds do Sit & Go.
public struct BlindLevel: Codable, Sendable, Equatable, Identifiable {
    public var id: Int { index }
    public let index: Int
    public let smallBlind: Int
    public let bigBlind: Int
    /// Duração do nível em segundos (timer da mesa).
    public let durationSeconds: Int

    public init(index: Int, smallBlind: Int, bigBlind: Int, durationSeconds: Int) {
        self.index = index
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.durationSeconds = durationSeconds
    }

    public var rotuloPT: String {
        "Nv. \(index + 1): \(smallBlind)/\(bigBlind)"
    }
}

/// Escala padrão de blinds para SNG de 1 mesa (chips iniciais ~1.500).
public enum BlindSchedule {
    /// Níveis progressivos; duração curta para UX mobile (ajustável nos testes).
    public static let padrao: [BlindLevel] = [
        BlindLevel(index: 0, smallBlind: 10, bigBlind: 20, durationSeconds: 90),
        BlindLevel(index: 1, smallBlind: 15, bigBlind: 30, durationSeconds: 90),
        BlindLevel(index: 2, smallBlind: 25, bigBlind: 50, durationSeconds: 90),
        BlindLevel(index: 3, smallBlind: 50, bigBlind: 100, durationSeconds: 75),
        BlindLevel(index: 4, smallBlind: 75, bigBlind: 150, durationSeconds: 75),
        BlindLevel(index: 5, smallBlind: 100, bigBlind: 200, durationSeconds: 60),
        BlindLevel(index: 6, smallBlind: 150, bigBlind: 300, durationSeconds: 60),
        BlindLevel(index: 7, smallBlind: 200, bigBlind: 400, durationSeconds: 60),
        BlindLevel(index: 8, smallBlind: 300, bigBlind: 600, durationSeconds: 45),
        BlindLevel(index: 9, smallBlind: 500, bigBlind: 1_000, durationSeconds: 45),
        BlindLevel(index: 10, smallBlind: 750, bigBlind: 1_500, durationSeconds: 45),
        BlindLevel(index: 11, smallBlind: 1_000, bigBlind: 2_000, durationSeconds: 45),
    ]

    public static func level(at index: Int, in schedule: [BlindLevel] = padrao) -> BlindLevel {
        let clamped = min(max(0, index), schedule.count - 1)
        return schedule[clamped]
    }

    /// Avança o índice; no último nível permanece (blinds máximos).
    public static func nextIndex(_ index: Int, in schedule: [BlindLevel] = padrao) -> Int {
        min(index + 1, schedule.count - 1)
    }
}
