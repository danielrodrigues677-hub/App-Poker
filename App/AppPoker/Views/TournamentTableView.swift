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
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BLINDS")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(model.session.nivelAtual.rotuloPT)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("PRÓXIMO NÍVEL")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timerTexto)
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(model.session.secondsRemainingInLevel <= 15 ? .orange : .primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("VIVOS")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(HoldemEngine.alivePlayerCount(state))")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)

            Text(model.session.statusMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.horizontalPadding)
                .fixedSize(horizontal: false, vertical: true)

            if let tip = model.coachTip, appModel.preferences.coachEnabled {
                CoachBanner(tip: tip)
                    .padding(.horizontal, AppTheme.horizontalPadding)
            }

            MesaInfoBar(
                street: state.street.nomePT,
                pot: state.pot,
                handNumber: state.handNumber
            )

            FeltBoard(communityCards: state.communityCards)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(state.players) { player in
                        JogadorLinha(
                            player: player,
                            isActor: state.currentActorIndex.map { state.players[$0].id == player.id } ?? false,
                            isDealer: state.players[state.dealerIndex].id == player.id
                        )
                    }
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }

            if let erro = model.erro {
                Text(erro)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            if state.street == .handOver && !model.session.isFinished {
                HandOverBar(
                    canReplay: model.session.lastHandReplay != nil,
                    onReplay: {
                        replay = model.session.lastHandReplay
                        model.showReplay = true
                    },
                    onNext: model.proximaMao
                )
            } else if model.session.isHumanTurn {
                AcoesBar(
                    legal: model.session.legalForHuman,
                    busy: model.busy,
                    onAction: model.agir
                )
            } else if !model.session.isFinished {
                ProgressView("Bots pensando…")
                    .padding(.bottom, 16)
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
