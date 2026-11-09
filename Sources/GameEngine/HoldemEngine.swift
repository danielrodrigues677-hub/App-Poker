import Foundation

/// Motor puro de Texas Hold'em No-Limit (cash). Sem UI.
public enum HoldemEngine {

    // MARK: - Setup

    public static func makeCashTable(config: CashConfig, humanName: String = "Você") -> TableState {
        let buyIn = config.preset.buyIn
        var players: [Player] = [
            Player(id: 0, name: humanName, kind: .human, stack: buyIn),
        ]
        for i in 1 ... config.botCount {
            players.append(Player(id: i, name: "Bot \(i)", kind: .bot, stack: buyIn))
        }
        return TableState(
            players: players,
            dealerIndex: players.count - 1,
            smallBlind: config.preset.smallBlind,
            bigBlind: config.preset.bigBlind,
            deckSeed: UInt64.random(in: 1 ... .max)
        )
    }

    /// Inicia uma nova mão. Exige pelo menos 2 jogadores com fichas.
    public static func startHand(_ state: TableState, seed: UInt64? = nil) -> TableState {
        var s = state
        let withChips = s.players.indices.filter { s.players[$0].stack > 0 }
        guard withChips.count >= 2 else {
            s.street = .handOver
            s.currentActorIndex = nil
            return s
        }

        s.handNumber += 1
        s.communityCards = []
        s.pot = 0
        s.currentBet = 0
        s.lastRaiseSize = s.bigBlind
        s.lastShowdown = nil
        s.winnersIfFold = nil
        s.deckSeed = seed ?? (s.deckSeed &+ UInt64(s.handNumber))

        for i in s.players.indices {
            s.players[i].holeCards = []
            s.players[i].betThisStreet = 0
            s.players[i].totalBetThisHand = 0
            s.players[i].isFolded = s.players[i].stack == 0
            s.players[i].isAllIn = false
            s.players[i].hasActedThisStreet = false
        }

        s.dealerIndex = nextSeated(from: s.dealerIndex, in: s)

        var deck = Deck(seed: s.deckSeed)

        let sb: Int
        let bb: Int
        if withChips.count == 2 {
            sb = s.dealerIndex
            bb = nextSeated(from: sb, in: s)
        } else {
            sb = nextSeated(from: s.dealerIndex, in: s)
            bb = nextSeated(from: sb, in: s)
        }

        postBlind(&s, at: sb, amount: s.smallBlind)
        postBlind(&s, at: bb, amount: s.bigBlind)
        s.currentBet = max(s.players[sb].betThisStreet, s.players[bb].betThisStreet)
        s.lastRaiseSize = s.bigBlind

        for _ in 0 ..< 2 {
            for idx in dealOrder(s) where !s.players[idx].isFolded {
                if let card = deck.deal() {
                    s.players[idx].holeCards.append(card)
                }
            }
        }

        s.street = .preflop
        if withChips.count == 2 {
            s.currentActorIndex = sb
        } else {
            s.currentActorIndex = nextInHand(from: bb, in: s)
        }
        return s
    }

    // MARK: - Legal actions

    public static func legalActions(for state: TableState, playerIndex: Int) -> LegalActions {
        guard [.preflop, .flop, .turn, .river].contains(state.street) else { return .none }
        guard state.currentActorIndex == playerIndex else { return .none }
        let p = state.players[playerIndex]
        guard p.canAct else { return .none }

        let toCall = max(0, state.currentBet - p.betThisStreet)
        let minRaiseTo = state.currentBet + max(state.lastRaiseSize, state.bigBlind)
        let maxRaiseTo = p.betThisStreet + p.stack

        if toCall == 0 {
            let canRaise = maxRaiseTo >= minRaiseTo
            return LegalActions(
                canFold: true,
                canCheck: true,
                canCall: false,
                callAmount: 0,
                canRaise: canRaise,
                minRaiseTo: minRaiseTo,
                maxRaiseTo: maxRaiseTo,
                canAllIn: p.stack > 0
            )
        }

        if toCall >= p.stack {
            return LegalActions(
                canFold: true,
                canCheck: false,
                canCall: false,
                callAmount: p.stack,
                canRaise: false,
                minRaiseTo: minRaiseTo,
                maxRaiseTo: maxRaiseTo,
                canAllIn: true
            )
        }

        let canRaise = maxRaiseTo >= minRaiseTo
        return LegalActions(
            canFold: true,
            canCheck: false,
            canCall: true,
            callAmount: toCall,
            canRaise: canRaise,
            minRaiseTo: minRaiseTo,
            maxRaiseTo: maxRaiseTo,
            canAllIn: true
        )
    }

    // MARK: - Apply

    public static func apply(_ action: PlayerAction, to state: TableState) throws -> TableState {
        guard let actor = state.currentActorIndex else { throw ActionError.handNotInProgress }
        guard [.preflop, .flop, .turn, .river].contains(state.street) else {
            throw ActionError.handNotInProgress
        }

        let legal = legalActions(for: state, playerIndex: actor)
        let p = state.players[actor]
        let toCall = max(0, state.currentBet - p.betThisStreet)

        switch action {
        case .fold:
            guard legal.canFold else { throw ActionError.illegalAction(action) }
        case .check:
            guard legal.canCheck else { throw ActionError.illegalAction(action) }
        case .call:
            guard legal.canCall else { throw ActionError.illegalAction(action) }
        case .raise(let to):
            guard legal.canRaise, to >= legal.minRaiseTo, to <= legal.maxRaiseTo else {
                throw ActionError.invalidRaiseAmount(min: legal.minRaiseTo, max: legal.maxRaiseTo)
            }
        case .allIn:
            guard p.stack > 0 else { throw ActionError.illegalAction(action) }
        }

        var s = state

        switch action {
        case .fold:
            s.players[actor].isFolded = true
            s.players[actor].hasActedThisStreet = true

        case .check:
            s.players[actor].hasActedThisStreet = true

        case .call:
            putChips(&s, at: actor, amount: toCall)
            s.players[actor].hasActedThisStreet = true

        case .raise(let to):
            let added = to - s.players[actor].betThisStreet
            let raiseSize = to - s.currentBet
            putChips(&s, at: actor, amount: added)
            s.lastRaiseSize = raiseSize
            s.currentBet = s.players[actor].betThisStreet
            reopenAction(except: actor, in: &s)
            s.players[actor].hasActedThisStreet = true

        case .allIn:
            let previousBet = s.currentBet
            let before = s.players[actor].betThisStreet
            putChips(&s, at: actor, amount: s.players[actor].stack)
            let newBet = s.players[actor].betThisStreet
            if newBet > previousBet {
                let raiseSize = newBet - previousBet
                if raiseSize >= max(s.lastRaiseSize, s.bigBlind) {
                    s.lastRaiseSize = raiseSize
                    reopenAction(except: actor, in: &s)
                }
                s.currentBet = newBet
            }
            _ = before
            s.players[actor].hasActedThisStreet = true
        }

        return continueAfterAction(s)
    }

    // MARK: - Flow

    private static func continueAfterAction(_ state: TableState) -> TableState {
        var s = state
        let remaining = s.players.indices.filter { s.players[$0].isInHand }
        if remaining.count == 1 {
            return winByFold(s, winnerIndex: remaining[0])
        }
        if let next = nextToAct(in: s) {
            s.currentActorIndex = next
            return s
        }
        return completeStreet(s)
    }

    private static func completeStreet(_ state: TableState) -> TableState {
        var s = state
        clearStreetBets(&s)

        switch s.street {
        case .preflop:
            dealCommunity(&s, count: 3)
            s.street = .flop
        case .flop:
            dealCommunity(&s, count: 1)
            s.street = .turn
        case .turn:
            dealCommunity(&s, count: 1)
            s.street = .river
        case .river:
            return performShowdown(s)
        default:
            return s
        }

        // Runout automático se restam < 2 jogadores que podem apostar
        let canBet = s.players.filter { $0.isInHand && !$0.isAllIn }.count
        if canBet < 2 {
            return runOut(s)
        }

        s.currentActorIndex = nextInHand(from: s.dealerIndex, in: s)
        // Garante que o ator consegue agir; senão avança
        if let idx = s.currentActorIndex, !s.players[idx].canAct {
            if let alt = nextToAct(in: s) {
                s.currentActorIndex = alt
            } else {
                return completeStreet(s)
            }
        }
        return s
    }

    private static func runOut(_ state: TableState) -> TableState {
        var s = state
        while s.street != .river {
            clearStreetBets(&s)
            switch s.street {
            case .flop:
                dealCommunity(&s, count: 1)
                s.street = .turn
            case .turn:
                dealCommunity(&s, count: 1)
                s.street = .river
            case .preflop:
                dealCommunity(&s, count: 3)
                s.street = .flop
            default:
                break
            }
        }
        clearStreetBets(&s)
        return performShowdown(s)
    }

    private static func clearStreetBets(_ s: inout TableState) {
        for i in s.players.indices {
            s.players[i].betThisStreet = 0
            s.players[i].hasActedThisStreet = false
        }
        s.currentBet = 0
        s.lastRaiseSize = s.bigBlind
        s.currentActorIndex = nil
    }

    private static func winByFold(_ state: TableState, winnerIndex: Int) -> TableState {
        var s = state
        s.players[winnerIndex].stack += s.pot
        s.winnersIfFold = [s.players[winnerIndex].id]
        s.pot = 0
        s.street = .handOver
        s.currentActorIndex = nil
        return s
    }

    private static func performShowdown(_ state: TableState) -> TableState {
        var s = state
        s.street = .showdown
        s.currentActorIndex = nil

        let contributions = Dictionary(uniqueKeysWithValues: s.players.map { ($0.id, $0.totalBetThisHand) })
        let folded = Set(s.players.filter(\.isFolded).map(\.id))
        let pots = PotCalculator.buildPots(contributions: contributions, foldedIds: folded)

        var ranks: [Int: HandRank] = [:]
        for p in s.players where p.isInHand {
            let cards = p.holeCards + s.communityCards
            if cards.count >= 5 {
                ranks[p.id] = HandEvaluator.bestHand(from: cards)
            }
        }

        var payouts: [Int: Int] = [:]
        var winnersByPot: [[Int]] = []

        for pot in pots {
            let eligible = pot.eligiblePlayerIds.filter { ranks[$0] != nil }
            guard let bestRank = eligible.compactMap({ ranks[$0] }).max() else {
                winnersByPot.append([])
                continue
            }
            let winners = eligible.filter { ranks[$0] == bestRank }.sorted()
            winnersByPot.append(winners)
            let share = pot.amount / max(winners.count, 1)
            var rem = pot.amount % max(winners.count, 1)
            for wid in winners {
                payouts[wid, default: 0] += share + (rem > 0 ? 1 : 0)
                if rem > 0 { rem -= 1 }
            }
        }

        for (pid, amount) in payouts {
            if let idx = s.players.firstIndex(where: { $0.id == pid }) {
                s.players[idx].stack += amount
            }
        }

        s.pot = 0
        s.lastShowdown = ShowdownResult(winnersByPot: winnersByPot, payouts: payouts, ranks: ranks)
        s.street = .handOver
        return s
    }

    // MARK: - Chips / deck / seats

    private static func postBlind(_ s: inout TableState, at index: Int, amount: Int) {
        putChips(&s, at: index, amount: min(amount, s.players[index].stack))
    }

    private static func putChips(_ s: inout TableState, at index: Int, amount: Int) {
        let pay = min(max(0, amount), s.players[index].stack)
        s.players[index].stack -= pay
        s.players[index].betThisStreet += pay
        s.players[index].totalBetThisHand += pay
        s.pot += pay
        if s.players[index].stack == 0 {
            s.players[index].isAllIn = true
        }
    }

    private static func reopenAction(except actor: Int, in s: inout TableState) {
        for i in s.players.indices where i != actor && s.players[i].canAct {
            s.players[i].hasActedThisStreet = false
        }
    }

    private static func dealCommunity(_ s: inout TableState, count: Int) {
        var deck = Deck(seed: s.deckSeed)
        let used = s.players.reduce(0) { $0 + $1.holeCards.count } + s.communityCards.count
        _ = deck.deal(used)
        _ = deck.deal() // burn
        s.communityCards.append(contentsOf: deck.deal(count))
    }

    /// Próximo assento com fichas (para blinds / botão).
    private static func nextSeated(from index: Int, in state: TableState) -> Int {
        let n = state.players.count
        for offset in 1 ... n {
            let idx = (index + offset) % n
            if state.players[idx].stack > 0 || state.players[idx].totalBetThisHand > 0 {
                // No início, stack>0; após blind parcial, ainda conta
                if !state.players[idx].isFolded || state.players[idx].stack > 0 {
                    if state.players[idx].stack > 0 { return idx }
                }
            }
            if state.players[idx].stack > 0 { return idx }
        }
        return (index + 1) % n
    }

    /// Próximo ainda na mão (não foldado).
    private static func nextInHand(from index: Int, in state: TableState) -> Int? {
        let n = state.players.count
        for offset in 1 ... n {
            let idx = (index + offset) % n
            if state.players[idx].isInHand { return idx }
        }
        return nil
    }

    private static func nextToAct(in state: TableState) -> Int? {
        guard let current = state.currentActorIndex else { return nil }
        let n = state.players.count
        for offset in 1 ... n {
            let idx = (current + offset) % n
            let p = state.players[idx]
            guard p.canAct else { continue }
            if !p.hasActedThisStreet || p.betThisStreet < state.currentBet {
                return idx
            }
        }
        return nil
    }

    private static func dealOrder(_ state: TableState) -> [Int] {
        let n = state.players.count
        return (1 ... n).map { (state.dealerIndex + $0) % n }
    }
}
