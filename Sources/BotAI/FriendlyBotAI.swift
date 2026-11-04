import Foundation
import GameEngine

/// Bot “amigável” (nível iniciante): folda mãos fracas, call/raise ocasional com força,
/// erra de propósito ~20%, raramente blefa. Heurística — sem solver.
public struct FriendlyBotAI: Sendable {
    public var mistakeRate: Double
    public var bluffRate: Double
    private var rng: SeededGenerator

    public init(seed: UInt64 = UInt64.random(in: 1 ... .max), mistakeRate: Double = 0.20, bluffRate: Double = 0.08) {
        self.mistakeRate = mistakeRate
        self.bluffRate = bluffRate
        self.rng = SeededGenerator(seed: seed)
    }

    public mutating func decide(state: TableState, playerIndex: Int) -> PlayerAction {
        let legal = HoldemEngine.legalActions(for: state, playerIndex: playerIndex)
        let options = usableOptions(legal)
        guard !options.isEmpty else { return legal.canCheck ? .check : .fold }

        let strength = estimatedStrength(state: state, playerIndex: playerIndex)
        var preferred = prefer(strength: strength, legal: legal, state: state, playerIndex: playerIndex)

        // Erro proposital
        if Double.random(in: 0 ... 1, using: &rng) < mistakeRate {
            preferred = options.randomElement(using: &rng) ?? preferred
        }

        // Blefe raro quando fraco e dá para raise/check-raise simplificado
        if strength < 0.25, Double.random(in: 0 ... 1, using: &rng) < bluffRate {
            if legal.canRaise {
                preferred = .raise(to: legal.minRaiseTo)
            } else if legal.canAllIn, state.players[playerIndex].stack <= state.bigBlind * 8 {
                preferred = .allIn
            }
        }

        if !legal.allows(preferred) && preferred != .allIn {
            // all-in pode ser permitido mesmo quando raise não
            if case .allIn = preferred, legal.canAllIn {
                return .allIn
            }
            return fallback(legal)
        }
        if case .allIn = preferred, !legal.canAllIn {
            return fallback(legal)
        }
        return preferred
    }

    // MARK: - Heurística

    /// 0...1 força relativa (preflop por carteira; pós-flop por categoria).
    private func estimatedStrength(state: TableState, playerIndex: Int) -> Double {
        let hole = state.players[playerIndex].holeCards
        guard hole.count == 2 else { return 0 }

        if state.communityCards.isEmpty {
            return preflopStrength(hole[0], hole[1])
        }

        let cards = hole + state.communityCards
        guard cards.count >= 5 else { return preflopStrength(hole[0], hole[1]) }
        let rank = HandEvaluator.bestHand(from: cards)
        switch rank.category {
        case .straightFlush, .fourOfAKind: return 0.98
        case .fullHouse: return 0.92
        case .flush: return 0.86
        case .straight: return 0.80
        case .threeOfAKind: return 0.72
        case .twoPair: return 0.60
        case .onePair:
            let pairRank = rank.tiebreakers.first ?? 0
            // Top pair-ish vs underpair
            let boardHigh = state.communityCards.map(\.rank.rawValue).max() ?? 0
            return pairRank >= boardHigh ? 0.52 : 0.38
        case .highCard:
            return 0.18
        }
    }

    private func preflopStrength(_ a: Card, _ b: Card) -> Double {
        let hi = max(a.rank.rawValue, b.rank.rawValue)
        let lo = min(a.rank.rawValue, b.rank.rawValue)
        let suited = a.suit == b.suit
        let paired = a.rank == b.rank

        if paired {
            return 0.45 + Double(hi) / 14.0 * 0.50 // 22≈0.59 … AA≈0.95
        }

        var score = Double(hi) / 14.0 * 0.45 + Double(lo) / 14.0 * 0.15
        if suited { score += 0.08 }
        if hi - lo == 1 { score += 0.05 } // conectores
        if hi == 14 { score += 0.06 } // ás
        return min(0.95, score)
    }

    private mutating func prefer(
        strength: Double,
        legal: LegalActions,
        state: TableState,
        playerIndex: Int
    ) -> PlayerAction {
        let potOddsPressure = legal.callAmount > 0
            ? Double(legal.callAmount) / Double(max(1, state.pot + legal.callAmount))
            : 0

        if strength < 0.28 {
            if legal.canCheck { return .check }
            // Folda a maioria; call raro se barato
            if legal.canCall, potOddsPressure < 0.12, Double.random(in: 0 ... 1, using: &rng) < 0.25 {
                return .call
            }
            return legal.canFold ? .fold : fallback(legal)
        }

        if strength < 0.45 {
            if legal.canCheck { return .check }
            if legal.canCall, potOddsPressure < 0.35 { return .call }
            return legal.canFold ? .fold : fallback(legal)
        }

        if strength < 0.65 {
            if legal.canRaise, Double.random(in: 0 ... 1, using: &rng) < 0.35 {
                return .raise(to: legal.minRaiseTo)
            }
            if legal.canCheck { return .check }
            if legal.canCall { return .call }
            return fallback(legal)
        }

        // Mão forte: raise / all-in ocasional short
        if legal.canRaise {
            let to: Int
            if strength > 0.85, Double.random(in: 0 ... 1, using: &rng) < 0.4 {
                to = min(legal.maxRaiseTo, legal.minRaiseTo + state.bigBlind * 4)
            } else {
                to = legal.minRaiseTo
            }
            return .raise(to: max(to, legal.minRaiseTo))
        }
        if legal.canAllIn, state.players[playerIndex].stack <= state.bigBlind * 12 {
            return .allIn
        }
        if legal.canCall { return .call }
        if legal.canCheck { return .check }
        return fallback(legal)
    }

    private func usableOptions(_ legal: LegalActions) -> [PlayerAction] {
        var list: [PlayerAction] = []
        if legal.canFold { list.append(.fold) }
        if legal.canCheck { list.append(.check) }
        if legal.canCall { list.append(.call) }
        if legal.canRaise { list.append(.raise(to: legal.minRaiseTo)) }
        if legal.canAllIn { list.append(.allIn) }
        return list
    }

    private func fallback(_ legal: LegalActions) -> PlayerAction {
        if legal.canCheck { return .check }
        if legal.canCall { return .call }
        if legal.canFold { return .fold }
        if legal.canAllIn { return .allIn }
        return .fold
    }
}
