import Foundation

public enum Suit: String, CaseIterable, Codable, Sendable, Hashable {
    case clubs = "♣"
    case diamonds = "♦"
    case hearts = "♥"
    case spades = "♠"

    public var nomePT: String {
        switch self {
        case .clubs: return "Paus"
        case .diamonds: return "Ouros"
        case .hearts: return "Copas"
        case .spades: return "Espadas"
        }
    }
}

public enum Rank: Int, CaseIterable, Codable, Sendable, Hashable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var simbolo: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }
}

public struct Card: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rank: Rank
    public let suit: Suit

    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    public var description: String {
        "\(rank.simbolo)\(suit.rawValue)"
    }

    public var rotuloPT: String {
        "\(rank.simbolo) de \(suit.nomePT)"
    }
}
