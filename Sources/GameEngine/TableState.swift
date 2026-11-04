import Foundation

public enum Street: String, Codable, Sendable, Comparable {
    case waiting
    case preflop
    case flop
    case turn
    case river
    case showdown
    case handOver

    public static func < (lhs: Street, rhs: Street) -> Bool {
        lhs.order < rhs.order
    }

    var order: Int {
        switch self {
        case .waiting: return 0
        case .preflop: return 1
        case .flop: return 2
        case .turn: return 3
        case .river: return 4
        case .showdown: return 5
        case .handOver: return 6
        }
    }

    var nomePT: String {
        switch self {
        case .waiting: return "Aguardando"
        case .preflop: return "Pré-flop"
        case .flop: return "Flop"
        case .turn: return "Turn"
        case .river: return "River"
        case .showdown: return "Showdown"
        case .handOver: return "Fim da mão"
        }
    }
}

public struct ShowdownResult: Equatable, Codable, Sendable {
    public let winnersByPot: [[Int]] // por pot, ids dos vencedores (split possível)
    public let payouts: [Int: Int] // playerId -> fichas ganhas
    public let ranks: [Int: HandRank] // só quem chegou ao showdown

    public init(winnersByPot: [[Int]], payouts: [Int: Int], ranks: [Int: HandRank]) {
        self.winnersByPot = winnersByPot
        self.payouts = payouts
        self.ranks = ranks
    }
}

public struct TableState: Sendable, Equatable {
    public var players: [Player]
    public var communityCards: [Card]
    public var street: Street
    public var dealerIndex: Int
    public var smallBlind: Int
    public var bigBlind: Int
    public var currentActorIndex: Int?
    public var currentBet: Int // maior aposta na street
    public var lastRaiseSize: Int
    public var pot: Int
    public var handNumber: Int
    public var lastShowdown: ShowdownResult?
    public var winnersIfFold: [Int]? // quando todos foldam menos um
    public var deckSeed: UInt64

    public var activePlayers: [Player] {
        players.filter(\.isInHand)
    }

    public var humanIndex: Int? {
        players.firstIndex { $0.kind == .human }
    }

    public init(
        players: [Player],
        communityCards: [Card] = [],
        street: Street = .waiting,
        dealerIndex: Int = 0,
        smallBlind: Int = 1,
        bigBlind: Int = 2,
        currentActorIndex: Int? = nil,
        currentBet: Int = 0,
        lastRaiseSize: Int = 0,
        pot: Int = 0,
        handNumber: Int = 0,
        lastShowdown: ShowdownResult? = nil,
        winnersIfFold: [Int]? = nil,
        deckSeed: UInt64 = 1
    ) {
        self.players = players
        self.communityCards = communityCards
        self.street = street
        self.dealerIndex = dealerIndex
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.currentActorIndex = currentActorIndex
        self.currentBet = currentBet
        self.lastRaiseSize = lastRaiseSize
        self.pot = pot
        self.handNumber = handNumber
        self.lastShowdown = lastShowdown
        self.winnersIfFold = winnersIfFold
        self.deckSeed = deckSeed
    }
}
