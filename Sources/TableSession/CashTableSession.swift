import Foundation
import GameEngine
import BotAI

/// Orquestra uma sessão cash vs bots: turnos do humano e decisões dos bots.
public final class CashTableSession: @unchecked Sendable {
    public private(set) var state: TableState
    public let config: CashConfig
    private var bot: FriendlyBotAI
    public var statusMessage: String

    public init(config: CashConfig, seed: UInt64? = nil) {
        self.config = config
        var table = HoldemEngine.makeCashTable(config: config)
        if let seed {
            table.deckSeed = seed
        }
        self.state = HoldemEngine.startHand(table, seed: seed)
        self.bot = FriendlyBotAI(seed: (seed ?? table.deckSeed) &+ 99)
        self.statusMessage = "Nova mão #\(self.state.handNumber)"
    }

    public var isHumanTurn: Bool {
        guard let idx = state.currentActorIndex else { return false }
        return state.players[idx].kind == .human
    }

    public var legalForHuman: LegalActions {
        guard let idx = state.humanIndex, isHumanTurn else { return .none }
        return HoldemEngine.legalActions(for: state, playerIndex: idx)
    }

    public func applyHuman(_ action: PlayerAction) throws {
        guard isHumanTurn else { throw ActionError.notPlayersTurn }
        state = try HoldemEngine.apply(action, to: state)
        statusMessage = mensagemAposAcao(action, nome: "Você")
        if state.street == .handOver {
            statusMessage = mensagemFimDeMao()
        }
    }

    /// Executa a ação do bot da vez. Retorna false se não for turno de bot.
    @discardableResult
    public func stepBot() throws -> Bool {
        guard let idx = state.currentActorIndex else { return false }
        guard state.players[idx].kind == .bot else { return false }
        let action = bot.decide(state: state, playerIndex: idx)
        state = try HoldemEngine.apply(action, to: state)
        statusMessage = mensagemAposAcao(action, nome: state.players[idx].name)
        if state.street == .handOver {
            statusMessage = mensagemFimDeMao()
        }
        return true
    }

    /// Avança bots até a vez do humano ou fim da mão. Limite evita loop infinito.
    public func runBotsUntilHumanOrEnd(maxSteps: Int = 64) throws {
        var steps = 0
        while steps < maxSteps {
            if state.street == .handOver { return }
            if isHumanTurn { return }
            guard try stepBot() else { return }
            steps += 1
        }
    }

    public func nextHand(seed: UInt64? = nil) {
        state = HoldemEngine.startHand(state, seed: seed)
        statusMessage = "Nova mão #\(state.handNumber)"
    }

    public var humanStack: Int {
        guard let idx = state.humanIndex else { return 0 }
        return state.players[idx].stack
    }

    private func mensagemAposAcao(_ action: PlayerAction, nome: String) -> String {
        switch action {
        case .fold: return "\(nome) desistiu"
        case .check: return "\(nome) passou"
        case .call: return "\(nome) pagou"
        case .raise(let to): return "\(nome) aumentou para \(to)"
        case .allIn: return "\(nome) foi all-in"
        }
    }

    private func mensagemFimDeMao() -> String {
        if let winners = state.winnersIfFold {
            let names = winners.compactMap { id in state.players.first { $0.id == id }?.name }
            return "\(names.joined(separator: ", ")) levou o pote (todos desistiram)"
        }
        if let sd = state.lastShowdown {
            let parts = sd.payouts.sorted { $0.key < $1.key }.compactMap { pid, amount -> String? in
                guard amount > 0, let name = state.players.first(where: { $0.id == pid })?.name else { return nil }
                let cat = sd.ranks[pid]?.category.description ?? ""
                return "\(name) +\(amount)" + (cat.isEmpty ? "" : " (\(cat))")
            }
            return parts.isEmpty ? "Mão encerrada" : "Showdown: " + parts.joined(separator: " · ")
        }
        return "Mão encerrada"
    }
}
