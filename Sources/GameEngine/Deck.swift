import Foundation

/// Baralho padrão de 52 cartas com embaralhamento seedável (testes / replay).
public struct Deck: Sendable {
    private var cards: [Card]
    private var rng: SeededGenerator

    public var remainingCount: Int { cards.count }

    public init(seed: UInt64 = UInt64.random(in: .min ... .max)) {
        cards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { Card(rank: $0, suit: suit) }
        }
        rng = SeededGenerator(seed: seed)
        shuffle()
    }

    public mutating func shuffle() {
        for i in stride(from: cards.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0 ... i, using: &rng)
            cards.swapAt(i, j)
        }
    }

    public mutating func deal() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeLast()
    }

    public mutating func deal(_ n: Int) -> [Card] {
        (0 ..< n).compactMap { _ in deal() }
    }

    public mutating func reset(seed: UInt64? = nil) {
        if let seed {
            rng = SeededGenerator(seed: seed)
        }
        cards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { Card(rank: $0, suit: suit) }
        }
        shuffle()
    }
}

/// Gerador determinístico (xorshift64*) para testes reproduzíveis.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed == 0 ? 0xDEAD_BEEF_CAFE_BABE : seed
    }

    public mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545_F491_4F6C_DD1D
    }
}
