import SwiftUI
import GameEngine
import TableSession
import Coach
import Persistence

@MainActor
final class TournamentViewModel: ObservableObject {
    @Published var session: SNGTableSession
    @Published var busy = false
    @Published var erro: String?
    @Published var coachTip: String?
    @Published var showResult = false
    @Published var showReplay = false

    private let coachEnabled: Bool
    private let advisor = CoachAdvisor()
    private var timerTask: Task<Void, Never>?
    var onHandFinished: ((HandReplay?) -> Void)?
    var onTournamentFinished: ((TournamentResult) -> Void)?

    init(config: SNGConfig, coachEnabled: Bool = true) {
        self.coachEnabled = coachEnabled
        session = SNGTableSession(config: config)
        refreshCoach()
        Task { await rodarBotsSePreciso() }
        startBlindTimer()
    }

    deinit {
        timerTask?.cancel()
    }

    var state: TableState { session.state }

    func agir(_ action: PlayerAction) {
        guard !busy else { return }
        do {
            try session.applyHuman(action)
            erro = nil
            persistHandIfNeeded()
            refreshCoach()
            if session.isFinished {
                presentResult()
            } else {
                Task { await rodarBotsSePreciso() }
            }
        } catch {
            erro = error.localizedDescription
        }
    }

    func proximaMao() {
        guard !session.isFinished else {
            presentResult()
            return
        }
        session.nextHand()
        if session.isFinished {
            presentResult()
            return
        }
        refreshCoach()
        Task { await rodarBotsSePreciso() }
    }

    private func presentResult() {
        showResult = true
        if let result = session.result {
            onTournamentFinished?(result)
        }
    }

    private func persistHandIfNeeded() {
        if session.state.street == .handOver || session.isFinished {
            onHandFinished?(session.lastHandReplay)
        }
    }

    private func refreshCoach() {
        guard coachEnabled, session.isHumanTurn else {
            coachTip = nil
            return
        }
        coachTip = advisor.tip(for: session.state, legal: session.legalForHuman)
    }

    private func startBlindTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, !Task.isCancelled else { return }
                let rose = self.session.tickBlindTimer(bySeconds: 1)
                if rose {
                    self.objectWillChange.send()
                } else {
                    self.objectWillChange.send()
                }
                if self.session.isFinished { return }
            }
        }
    }

    private func rodarBotsSePreciso() async {
        busy = true
        defer { busy = false }
        do {
            while !session.isFinished && session.state.street != .handOver {
                if session.isHumanTurn {
                    refreshCoach()
                    return
                }
                // Humano eliminado: segue a mesa automaticamente
                let humanAlive = session.state.humanIndex.map { session.state.players[$0].stack > 0 } ?? false
                if !humanAlive && session.state.street != .handOver {
                    try await Task.sleep(nanoseconds: 400_000_000)
                } else {
                    try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000 ... 1_000_000_000))
                }
                _ = try session.stepBot()
                persistHandIfNeeded()
                if session.isFinished {
                    presentResult()
                    return
                }
            }
            if session.state.street == .handOver {
                persistHandIfNeeded()
                if session.isFinished {
                    presentResult()
                } else if !(session.state.humanIndex.map { session.state.players[$0].stack > 0 } ?? false) {
                    // Auto-avança mãos após eliminação do humano
                    try await Task.sleep(nanoseconds: 800_000_000)
                    proximaMao()
                }
            }
        } catch {
            erro = error.localizedDescription
        }
    }
}

struct TournamentTableView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var model: TournamentViewModel
    @State private var replay: HandReplay?

    init(config: SNGConfig) {
        _model = StateObject(wrappedValue: TournamentViewModel(config: config, coachEnabled: true))
    }

    var body: some View {
        let state = model.state
        VStack(spacing: 10) {
            HStack {
                Text(model.session.nivelAtual.rotuloPT)
                    .fontWeight(.semibold)
                Spacer()
                Text(timerTexto)
                    .monospacedDigit()
                    .foregroundStyle(model.session.secondsRemainingInLevel <= 15 ? .orange : .secondary)
                Spacer()
                Text("Vivos: \(HoldemEngine.alivePlayerCount(state))")
            }
            .font(.subheadline)
            .padding(.horizontal)

            Text(model.session.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let tip = model.coachTip, appModel.preferences.coachEnabled {
                Text(tip)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
            }

            HStack {
                Text(state.street.nomePT)
                Spacer()
                Text("Pote: \(state.pot)").fontWeight(.semibold)
                Spacer()
                Text("Mão #\(state.handNumber)")
            }
            .font(.subheadline)
            .padding(.horizontal)

            HStack(spacing: 6) {
                ForEach(Array(state.communityCards.enumerated()), id: \.offset) { _, card in
                    CartaView(card: card)
                }
                if state.communityCards.isEmpty {
                    Text("Sem cartas comunitárias")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 0.12, green: 0.38, blue: 0.22))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(state.players) { player in
                        JogadorLinha(
                            player: player,
                            isActor: state.currentActorIndex.map { state.players[$0].id == player.id } ?? false,
                            isDealer: state.players[state.dealerIndex].id == player.id
                        )
                    }
                }
                .padding(.horizontal)
            }

            if let erro = model.erro {
                Text(erro).font(.caption).foregroundStyle(.red)
            }

            if state.street == .handOver && !model.session.isFinished {
                HStack {
                    if model.session.lastHandReplay != nil {
                        Button("Replay") {
                            replay = model.session.lastHandReplay
                            model.showReplay = true
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Próxima mão") { model.proximaMao() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            } else if model.session.isHumanTurn {
                AcoesBar(
                    legal: model.session.legalForHuman,
                    busy: model.busy,
                    onAction: model.agir
                )
                .padding(.bottom, 8)
            } else if !model.session.isFinished {
                ProgressView("Bots pensando…")
                    .padding(.bottom)
            }
        }
        .navigationTitle("Sit & Go")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $model.showResult) {
            if let result = model.session.result {
                TournamentResultView(result: result, replay: model.session.lastHandReplay)
            }
        }
        .sheet(isPresented: $model.showReplay) {
            if let replay {
                NavigationStack {
                    HandReplayView(replay: replay)
                }
            }
        }
        .onAppear {
            // Reconfigura coach conforme preferências atuais
            model.onHandFinished = { replay in
                appModel.persistReplay(replay)
            }
            model.onTournamentFinished = { result in
                appModel.persistSession(
                    SessionSummary(
                        kind: "sng",
                        detailPT: result.humanFinished
                            ? "Campeão do Sit & Go (\(result.handsPlayed) mãos)"
                            : "SNG · \(result.humanPlace)º lugar · \(result.handsPlayed) mãos",
                        handsPlayed: result.handsPlayed
                    )
                )
            }
        }
    }

    private var timerTexto: String {
        let s = max(0, model.session.secondsRemainingInLevel)
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }
}
