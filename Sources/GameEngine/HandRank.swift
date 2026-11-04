import Foundation

public enum HandCategory: Int, Comparable, Codable, Sendable, CustomStringConvertible {
    case highCard = 0
    case onePair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush

    public static func < (lhs: HandCategory, rhs: HandCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .highCard: return "Carta alta"
        case .onePair: return "Um par"
        case .twoPair: return "Dois pares"
        case .threeOfAKind: return "Trinca"
        case .straight: return "Sequência"
        case .flush: return "Flush"
        case .fullHouse: return "Full house"
        case .fourOfAKind: return "Quadra"
        case .straightFlush: return "Straight flush"
        }
    }
}

/// Ranking comparável de uma mão de 5 cartas (maior = melhor).
public struct HandRank: Comparable, Codable, Sendable, CustomStringConvertible {
    public let category: HandCategory
    /// Kickers / valores de desempate, do mais importante ao menos (ranks 2...14).
    public let tiebreakers: [Int]

    public init(category: HandCategory, tiebreakers: [Int]) {
        self.category = category
        self.tiebreakers = tiebreakers
    }

    public static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        if lhs.category != rhs.category {
            return lhs.category < rhs.category
        }
        for (a, b) in zip(lhs.tiebreakers, rhs.tiebreakers) where a != b {
            return a < b
        }
        return false
    }

    public var description: String {
        "\(category.description) \(tiebreakers)"
    }
}

public enum HandEvaluator {
    /// Melhor mão de 5 cartas a partir de 5–7 cartas (Hold'em).
    public static func bestHand(from cards: [Card]) -> HandRank {
        precondition((5 ... 7).contains(cards.count), "Hold'em exige 5 a 7 cartas")
        var best: HandRank?
        for combo in combinations(cards, k: 5) {
            let rank = evaluateFive(combo)
            if best == nil || rank > best! {
                best = rank
            }
        }
        return best!
    }

    public static func evaluateFive(_ cards: [Card]) -> HandRank {
        precondition(cards.count == 5)
        let ranksDesc = cards.map(\.rank.rawValue).sorted(by: >)
        let isFlush = cards.allSatisfy { $0.suit == cards[0].suit }
        let straightHigh = straightHigh(from: Set(ranksDesc))

        if isFlush, let high = straightHigh {
            return HandRank(category: .straightFlush, tiebreakers: [high])
        }

        let byRank = Dictionary(grouping: ranksDesc, by: { $0 })
            .map { (rank: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.rank > rhs.rank
            }

        if byRank[0].count == 4 {
            return HandRank(category: .fourOfAKind, tiebreakers: [byRank[0].rank, byRank[1].rank])
        }

        if byRank[0].count == 3, byRank.count > 1, byRank[1].count == 2 {
            return HandRank(category: .fullHouse, tiebreakers: [byRank[0].rank, byRank[1].rank])
        }

        if isFlush {
            return HandRank(category: .flush, tiebreakers: ranksDesc)
        }

        if let high = straightHigh {
            return HandRank(category: .straight, tiebreakers: [high])
        }

        if byRank[0].count == 3 {
            let kickers = byRank.dropFirst().map(\.rank)
            return HandRank(category: .threeOfAKind, tiebreakers: [byRank[0].rank] + kickers)
        }

        if byRank[0].count == 2, byRank.count > 1, byRank[1].count == 2 {
            let highPair = max(byRank[0].rank, byRank[1].rank)
            let lowPair = min(byRank[0].rank, byRank[1].rank)
            return HandRank(category: .twoPair, tiebreakers: [highPair, lowPair, byRank[2].rank])
        }

        if byRank[0].count == 2 {
            let kickers = byRank.dropFirst().map(\.rank)
            return HandRank(category: .onePair, tiebreakers: [byRank[0].rank] + kickers)
        }

        return HandRank(category: .highCard, tiebreakers: ranksDesc)
    }

    /// Retorna a carta alta da sequência, ou nil. Wheel (A2345) = 5.
    private static func straightHigh(from ranks: Set<Int>) -> Int? {
        let patterns: [(Set<Int>, Int)] = [
            ([14, 13, 12, 11, 10], 14),
            ([13, 12, 11, 10, 9], 13),
            ([12, 11, 10, 9, 8], 12),
            ([11, 10, 9, 8, 7], 11),
            ([10, 9, 8, 7, 6], 10),
            ([9, 8, 7, 6, 5], 9),
            ([8, 7, 6, 5, 4], 8),
            ([7, 6, 5, 4, 3], 7),
            ([6, 5, 4, 3, 2], 6),
            ([14, 5, 4, 3, 2], 5),
        ]
        for (pattern, high) in patterns where ranks == pattern {
            return high
        }
        return nil
    }

    private static func combinations<T>(_ array: [T], k: Int) -> [[T]] {
        guard k > 0, k <= array.count else { return [] }
        if k == array.count { return [array] }
        if k == 1 { return array.map { [$0] } }

        var result: [[T]] = []
        func recurse(start: Int, path: [T]) {
            if path.count == k {
                result.append(path)
                return
            }
            for i in start ..< array.count {
                recurse(start: i + 1, path: path + [array[i]])
            }
        }
        recurse(start: 0, path: [])
        return result
    }
}
