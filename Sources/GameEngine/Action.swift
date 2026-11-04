import Foundation

public enum PlayerAction: Equatable, Sendable, Codable {
    case fold
    case check
    case call
    case raise(to: Int) // valor total na street (não o delta)
    case allIn

    public var nomePT: String {
        switch self {
        case .fold: return "Desistir"
        case .check: return "Passar"
        case .call: return "Pagar"
        case .raise: return "Aumentar"
        case .allIn: return "All-in"
        }
    }
}

public enum ActionError: Error, Equatable, CustomStringConvertible {
    case notPlayersTurn
    case playerCannotAct
    case illegalAction(PlayerAction)
    case handNotInProgress
    case invalidRaiseAmount(min: Int, max: Int)

    public var description: String {
        switch self {
        case .notPlayersTurn: return "Não é a vez deste jogador"
        case .playerCannotAct: return "Jogador não pode agir"
        case .illegalAction(let a): return "Ação ilegal: \(a.nomePT)"
        case .handNotInProgress: return "Nenhuma mão em andamento"
        case .invalidRaiseAmount(let min, let max):
            return "Aumento inválido (mín \(min), máx \(max))"
        }
    }
}

public struct LegalActions: Equatable, Sendable {
    public let canFold: Bool
    public let canCheck: Bool
    public let canCall: Bool
    public let callAmount: Int
    public let canRaise: Bool
    public let minRaiseTo: Int
    public let maxRaiseTo: Int
    public let canAllIn: Bool

    public static let none = LegalActions(
        canFold: false,
        canCheck: false,
        canCall: false,
        callAmount: 0,
        canRaise: false,
        minRaiseTo: 0,
        maxRaiseTo: 0,
        canAllIn: false
    )

    public func allows(_ action: PlayerAction) -> Bool {
        switch action {
        case .fold: return canFold
        case .check: return canCheck
        case .call: return canCall
        case .raise(let to):
            return canRaise && to >= minRaiseTo && to <= maxRaiseTo
        case .allIn: return canAllIn
        }
    }

    public var asArray: [PlayerAction] {
        var list: [PlayerAction] = []
        if canFold { list.append(.fold) }
        if canCheck { list.append(.check) }
        if canCall { list.append(.call) }
        if canRaise { list.append(.raise(to: minRaiseTo)) }
        if canAllIn { list.append(.allIn) }
        return list
    }
}
