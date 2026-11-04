import Foundation

public enum PlayerKind: String, Codable, Sendable {
    case human
    case bot
}

public struct Player: Identifiable, Codable, Sendable, Equatable {
    public let id: Int
    public var name: String
    public var kind: PlayerKind
    public var stack: Int
    public var holeCards: [Card]
    public var betThisStreet: Int
    public var totalBetThisHand: Int
    public var isFolded: Bool
    public var isAllIn: Bool
    public var hasActedThisStreet: Bool

    public var isInHand: Bool { !isFolded }
    public var canAct: Bool { isInHand && !isAllIn && stack > 0 }

    public init(
        id: Int,
        name: String,
        kind: PlayerKind,
        stack: Int,
        holeCards: [Card] = [],
        betThisStreet: Int = 0,
        totalBetThisHand: Int = 0,
        isFolded: Bool = false,
        isAllIn: Bool = false,
        hasActedThisStreet: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.stack = stack
        self.holeCards = holeCards
        self.betThisStreet = betThisStreet
        self.totalBetThisHand = totalBetThisHand
        self.isFolded = isFolded
        self.isAllIn = isAllIn
        self.hasActedThisStreet = hasActedThisStreet
    }
}
