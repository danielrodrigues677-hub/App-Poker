import Foundation

/// Snapshot de uma ação para replay.
public struct HandActionRecord: Codable, Sendable, Equatable {
    public let street: Street
    public let playerId: Int
    public let playerName: String
    public let action: PlayerAction
    public let potAfter: Int

    public init(street: Street, playerId: Int, playerName: String, action: PlayerAction, potAfter: Int) {
        self.street = street
        self.playerId = playerId
        self.playerName = playerName
        self.action = action
        self.potAfter = potAfter
    }
}

/// Estado de cartas por street (para highlight no replay).
public struct StreetSnapshot: Codable, Sendable, Equatable {
    public let street: Street
    public let communityCards: [Card]

    public init(street: Street, communityCards: [Card]) {
        self.street = street
        self.communityCards = communityCards
    }
}

/// Replay da última mão (persistível).
public struct HandReplay: Codable, Sendable, Equatable, Identifiable {
    public var id: String { "\(handNumber)-\(deckSeed)" }
    public let handNumber: Int
    public let deckSeed: UInt64
    public let smallBlind: Int
    public let bigBlind: Int
    public let humanHoleCards: [Card]
    public let playerNames: [Int: String]
    public let streets: [StreetSnapshot]
    public let actions: [HandActionRecord]
    public let resultSummary: String
    public let recordedAt: Date

    public init(
        handNumber: Int,
        deckSeed: UInt64,
        smallBlind: Int,
        bigBlind: Int,
        humanHoleCards: [Card],
        playerNames: [Int: String],
        streets: [StreetSnapshot],
        actions: [HandActionRecord],
        resultSummary: String,
        recordedAt: Date = Date()
    ) {
        self.handNumber = handNumber
        self.deckSeed = deckSeed
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.humanHoleCards = humanHoleCards
        self.playerNames = playerNames
        self.streets = streets
        self.actions = actions
        self.resultSummary = resultSummary
        self.recordedAt = recordedAt
    }
}

/// Acumulador mutável durante uma mão.
public struct HandRecorder: Sendable {
    public private(set) var handNumber: Int = 0
    public private(set) var deckSeed: UInt64 = 0
    public private(set) var smallBlind: Int = 0
    public private(set) var bigBlind: Int = 0
    public private(set) var humanHoleCards: [Card] = []
    public private(set) var playerNames: [Int: String] = [:]
    public private(set) var streets: [StreetSnapshot] = []
    public private(set) var actions: [HandActionRecord] = []
    private var lastStreet: Street?

    public init() {}

    public mutating func beginHand(from state: TableState) {
        handNumber = state.handNumber
        deckSeed = state.deckSeed
        smallBlind = state.smallBlind
        bigBlind = state.bigBlind
        humanHoleCards = state.humanIndex.map { state.players[$0].holeCards } ?? []
        playerNames = Dictionary(uniqueKeysWithValues: state.players.map { ($0.id, $0.name) })
        streets = [StreetSnapshot(street: state.street, communityCards: state.communityCards)]
        actions = []
        lastStreet = state.street
    }

    public mutating func noteState(_ state: TableState) {
        if state.street != lastStreet, [.preflop, .flop, .turn, .river, .showdown, .handOver].contains(state.street) {
            streets.append(StreetSnapshot(street: state.street, communityCards: state.communityCards))
            lastStreet = state.street
        }
        if humanHoleCards.isEmpty, let idx = state.humanIndex, state.players[idx].holeCards.count == 2 {
            humanHoleCards = state.players[idx].holeCards
        }
    }

    public mutating func record(action: PlayerAction, by playerIndex: Int, in state: TableState) {
        let p = state.players[playerIndex]
        actions.append(
            HandActionRecord(
                street: state.street,
                playerId: p.id,
                playerName: p.name,
                action: action,
                potAfter: state.pot
            )
        )
    }

    public func finish(resultSummary: String) -> HandReplay {
        HandReplay(
            handNumber: handNumber,
            deckSeed: deckSeed,
            smallBlind: smallBlind,
            bigBlind: bigBlind,
            humanHoleCards: humanHoleCards,
            playerNames: playerNames,
            streets: streets,
            actions: actions,
            resultSummary: resultSummary
        )
    }
}
