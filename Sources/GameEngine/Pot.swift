import Foundation

public struct PotShare: Equatable, Codable, Sendable {
    public let amount: Int
    public let eligiblePlayerIds: [Int]

    public init(amount: Int, eligiblePlayerIds: [Int]) {
        self.amount = amount
        self.eligiblePlayerIds = eligiblePlayerIds
    }
}

public enum PotCalculator {
    /// Calcula pot principal + side pots a partir das contribuições totais da mão.
    /// `contributions`: playerId -> fichas colocadas na mão (ainda que tenha foldado).
    /// Foldados não recebem, mas suas fichas entram no pot.
    public static func buildPots(
        contributions: [Int: Int],
        foldedIds: Set<Int>
    ) -> [PotShare] {
        let positive = contributions.filter { $0.value > 0 }
        guard !positive.isEmpty else { return [] }

        let levels = Set(positive.values).sorted()
        var pots: [PotShare] = []
        var previous = 0

        for level in levels {
            let layer = level - previous
            guard layer > 0 else { continue }
            let contributors = positive.filter { $0.value >= level }.map(\.key)
            let amount = layer * contributors.count
            let eligible = contributors.filter { !foldedIds.contains($0) }.sorted()
            if amount > 0 {
                pots.append(PotShare(amount: amount, eligiblePlayerIds: eligible))
            }
            previous = level
        }

        // Mesclar pots consecutivos com os mesmos elegíveis
        var merged: [PotShare] = []
        for pot in pots {
            if let last = merged.last, last.eligiblePlayerIds == pot.eligiblePlayerIds {
                merged[merged.count - 1] = PotShare(
                    amount: last.amount + pot.amount,
                    eligiblePlayerIds: last.eligiblePlayerIds
                )
            } else {
                merged.append(pot)
            }
        }
        return merged
    }
}
