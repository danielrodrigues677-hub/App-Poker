import Foundation
import GameEngine
import BotAI

public struct TournamentResult: Sendable, Equatable {
    public let winnerId: Int
    public let winnerName: String
    public let humanFinished: Bool
    public let humanPlace: Int
    public let handsPlayed: Int
    public let finalBlindLevel: Int
    public let tipPT: String

    public init(
        winnerId: Int,
        winnerName: String,
        humanFinished: Bool,
        humanPlace: Int,
        handsPlayed: Int,
        finalBlindLevel: Int,
        tipPT: String
    ) {
        self.winnerId = winnerId
        self.winnerName = winnerName
        self.humanFinished = humanFinished
        self.humanPlace = humanPlace
        self.handsPlayed = handsPlayed
        self.finalBlindLevel = finalBlindLevel
        self.tipPT = tipPT
    }
}

/// Orquestra Sit & Go de 1 mesa: blinds por timer, eliminação até 1 vencedor.
public final class SNGTableSession: @unchecked Sendable {
    public private(set) var state: TableState
    public let config: SNGConfig
    private var bot: FriendlyBotAI
    public var statusMessage: String

    public private(set) var blindLevelIndex: Int = 0
    /// Segundos restantes no nível atual (pode ser avançado nos testes).
    public private(set) var secondsRemainingInLevel: Int
    public private(set) var isFinished: Bool = false
    public private(set) var result: TournamentResult?
    /// Ordem de eliminação (ids), do primeiro eliminado ao último antes do campeão.
    public private(set) var eliminationOrder: [Int] = []
    public private(set) var lastHandReplay: HandReplay?
    private var recorder = HandRecorder()
    private var knownAlive: Set<Int>

    public init(config: SNGConfig, seed: UInt64? = nil) {
        self.config = config
        var table = HoldemEngine.makeSNGTable(config: config)
        if let seed {
            table.deckSeed = seed
        }
        let level0 = BlindSchedule.level(at: 0, in: config.schedule)
        table.smallBlind = level0.smallBlind
        table.bigBlind = level0.bigBlind
        let started = HoldemEngine.startHand(table, seed: seed)
        self.state = started
        self.bot = FriendlyBotAI(seed: (seed ?? table.deckSeed) &+ 77)
        self.secondsRemainingInLevel = level0.durationSeconds
        self.knownAlive = Set(started.players.map(\.id))
        var recorder = HandRecorder()
        recorder.beginHand(from: started)
        self.recorder = recorder
        self.statusMessage = "Sit & Go · mão #\(started.handNumber) · \(level0.rotuloPT)"
    }

    public var nivelAtual: BlindLevel {
        BlindSchedule.level(at: blindLevelIndex, in: config.schedule)
    }

    public var isHumanTurn: Bool {
        guard let idx = state.currentActorIndex else { return false }
        return state.players[idx].kind == .human
    }

    public var humanStillAlive: Bool {
        guard let idx = state.humanIndex else { return false }
        return state.players[idx].stack > 0 || state.street != .handOver && state.players[idx].isInHand
    }

    public var legalForHuman: LegalActions {
        guard let idx = state.humanIndex, isHumanTurn else { return .none }
        return HoldemEngine.legalActions(for: state, playerIndex: idx)
    }

    public func applyHuman(_ action: PlayerAction) throws {
        guard !isFinished else { return }
        guard isHumanTurn else { throw ActionError.notPlayersTurn }
        guard let actor = state.currentActorIndex else { throw ActionError.notPlayersTurn }
        recorder.record(action: action, by: actor, in: state)
        state = try HoldemEngine.apply(action, to: state)
        recorder.noteState(state)
        statusMessage = mensagemAposAcao(action, nome: "Você")
        if state.street == .handOver {
            finalizeHandIfNeeded()
        }
    }

    @discardableResult
    public func stepBot() throws -> Bool {
        guard !isFinished else { return false }
        guard let idx = state.currentActorIndex else { return false }
        guard state.players[idx].kind == .bot else { return false }
        let action = bot.decide(state: state, playerIndex: idx)
        recorder.record(action: action, by: idx, in: state)
        state = try HoldemEngine.apply(action, to: state)
        recorder.noteState(state)
        statusMessage = mensagemAposAcao(action, nome: state.players[idx].name)
        if state.street == .handOver {
            finalizeHandIfNeeded()
        }
        return true
    }

    public func runBotsUntilHumanOrEnd(maxSteps: Int = 96) throws {
        var steps = 0
        while steps < maxSteps {
            if isFinished || state.street == .handOver { return }
            if isHumanTurn { return }
            // Humano eliminado: bots jogam entre si
            if !playerCanAct(.human) {
                guard try stepBot() else { return }
            } else {
                guard try stepBot() else { return }
            }
            steps += 1
        }
    }

    /// Avança o timer do nível. Retorna true se o nível de blinds subiu.
    @discardableResult
    public func tickBlindTimer(bySeconds seconds: Int = 1) -> Bool {
        guard !isFinished else { return false }
        guard seconds > 0 else { return false }
        secondsRemainingInLevel -= seconds
        if secondsRemainingInLevel > 0 { return false }
        return advanceBlindLevel()
    }

    /// Força avanço de nível (útil em testes).
    @discardableResult
    public func advanceBlindLevel() -> Bool {
        guard !isFinished else { return false }
        let previous = blindLevelIndex
        blindLevelIndex = BlindSchedule.nextIndex(blindLevelIndex, in: config.schedule)
        secondsRemainingInLevel = nivelAtual.durationSeconds
        // Blinds só entram na próxima mão
        if state.street == .waiting || state.street == .handOver {
            applyBlindsToState()
        }
        if blindLevelIndex != previous {
            statusMessage = "Blinds sobem · \(nivelAtual.rotuloPT)"
            return true
        }
        return false
    }

    public func nextHand(seed: UInt64? = nil) {
        guard !isFinished else { return }
        noteEliminations()
        if checkTournamentOver() { return }

        applyBlindsToState()
        // Remover efetivamente: stacks 0 ficam foldados no startHand
        state = HoldemEngine.startHand(state, seed: seed)
        if HoldemEngine.alivePlayerCount(state) < 2 {
            _ = checkTournamentOver()
            return
        }
        recorder = HandRecorder()
        recorder.beginHand(from: state)
        statusMessage = "Mão #\(state.handNumber) · \(nivelAtual.rotuloPT)"
    }

    public var humanStack: Int {
        guard let idx = state.humanIndex else { return 0 }
        return state.players[idx].stack
    }

    // MARK: - Privado

    private func playerCanAct(_ kind: PlayerKind) -> Bool {
        state.players.contains { $0.kind == kind && $0.stack > 0 }
    }

    private func applyBlinds(to table: inout TableState, levelIndex: Int) {
        let level = BlindSchedule.level(at: levelIndex, in: config.schedule)
        table.smallBlind = level.smallBlind
        table.bigBlind = level.bigBlind
    }

    private func applyBlindsToState() {
        applyBlinds(to: &state, levelIndex: blindLevelIndex)
    }

    private func finalizeHandIfNeeded() {
        statusMessage = mensagemFimDeMao()
        lastHandReplay = recorder.finish(resultSummary: statusMessage)
        noteEliminations()
        _ = checkTournamentOver()
    }

    private func noteEliminations() {
        let aliveNow = Set(state.players.filter { $0.stack > 0 }.map(\.id))
        let newlyOut = knownAlive.subtracting(aliveNow)
        for id in newlyOut.sorted() {
            if !eliminationOrder.contains(id) {
                eliminationOrder.append(id)
            }
        }
        knownAlive = aliveNow
    }

    @discardableResult
    private func checkTournamentOver() -> Bool {
        if let winner = HoldemEngine.tournamentWinner(in: state) {
            finish(winner: winner)
            return true
        }
        // Humano sem fichas e mão acabou: ainda pode haver campeão entre bots — continua
        if HoldemEngine.alivePlayerCount(state) < 2 {
            if let winner = state.players.max(by: { $0.stack < $1.stack }) {
                finish(winner: winner)
                return true
            }
        }
        return false
    }

    private func finish(winner: Player) {
        guard !isFinished else { return }
        isFinished = true
        let humanId = state.humanIndex.map { state.players[$0].id }
        let humanPlace: Int
        if let hid = humanId {
            if winner.id == hid {
                humanPlace = 1
            } else if let elimIndex = eliminationOrder.firstIndex(of: hid) {
                // eliminationOrder: primeiro eliminado = último lugar
                humanPlace = config.seatCount - elimIndex
            } else if state.players.first(where: { $0.id == hid })?.stack == 0 {
                humanPlace = config.seatCount - eliminationOrder.count + 1
            } else {
                humanPlace = 2
            }
        } else {
            humanPlace = config.seatCount
        }

        let tip: String
        if winner.kind == .human {
            tip = "Parabéns! Tente variar o tamanho dos aumentos e observe a posição relativa aos blinds."
        } else if humanPlace <= 3 {
            tip = "Chegou longe. Revise quando pagar aumentos altos pré-flop com mãos médias."
        } else {
            tip = "Foque em mãos fortes cedo e evite ir all-in sem necessidade nos blinds baixos."
        }

        result = TournamentResult(
            winnerId: winner.id,
            winnerName: winner.name,
            humanFinished: winner.kind == .human,
            humanPlace: humanPlace,
            handsPlayed: state.handNumber,
            finalBlindLevel: blindLevelIndex + 1,
            tipPT: tip
        )
        statusMessage = "Torneio encerrado · campeão: \(winner.name)"
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
