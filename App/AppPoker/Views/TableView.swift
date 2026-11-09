import SwiftUI
import GameEngine
import TableSession
import Coach
import Persistence

@MainActor
final class TableViewModel: ObservableObject {
    @Published var session: CashTableSession
    @Published var busy = false
    @Published var erro: String?
    @Published var coachTip: String?
    @Published var showReplay = false

    private let coachEnabled: Bool
    private let advisor = CoachAdvisor()
    var onHandFinished: ((HandReplay?) -> Void)?

    init(config: CashConfig, coachEnabled: Bool = true) {
        self.coachEnabled = coachEnabled
        session = CashTableSession(config: config)
        refreshCoach()
        Task { await rodarBotsSePreciso() }
    }

    var state: TableState { session.state }

    func agir(_ action: PlayerAction) {
        guard !busy else { return }
        do {
            try session.applyHuman(action)
            erro = nil
            if session.state.street == .handOver {
                onHandFinished?(session.lastHandReplay)
            }
            refreshCoach()
            Task { await rodarBotsSePreciso() }
        } catch {
            erro = error.localizedDescription
        }
    }

    func proximaMao() {
        session.nextHand()
        refreshCoach()
        Task { await rodarBotsSePreciso() }
    }

    private func refreshCoach() {
        guard coachEnabled, session.isHumanTurn else {
            coachTip = nil
            return
        }
        coachTip = advisor.tip(for: session.state, legal: session.legalForHuman)
    }

    private func rodarBotsSePreciso() async {
        busy = true
        defer { busy = false }
        do {
            while session.state.street != .handOver && !session.isHumanTurn {
                try await Task.sleep(nanoseconds: UInt64.random(in: 600_000_000 ... 1_200_000_000))
                _ = try session.stepBot()
                if session.state.street == .handOver {
                    onHandFinished?(session.lastHandReplay)
                }
            }
            refreshCoach()
        } catch {
            erro = error.localizedDescription
        }
    }
}

struct TableView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var model: TableViewModel
    @State private var replay: HandReplay?

    init(config: CashConfig) {
        _model = StateObject(wrappedValue: TableViewModel(config: config))
    }

    var body: some View {
        let state = model.state
        VStack(spacing: AppTheme.sectionSpacing) {
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

            if state.street == .handOver {
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
            } else {
                ProgressView("Bots pensando…")
                    .padding(.bottom, 16)
            }
        }
        .navigationTitle("Mesa cash")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $model.showReplay) {
            if let replay {
                NavigationStack {
                    HandReplayView(replay: replay)
                }
            }
        }
        .onAppear {
            model.onHandFinished = { hand in
                appModel.persistReplay(hand)
                if let hand {
                    appModel.persistSession(
                        SessionSummary(
                            kind: "cash",
                            detailPT: "Cash · mão #\(hand.handNumber) · \(hand.resultSummary)",
                            handsPlayed: hand.handNumber
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TableView(config: CashConfig(preset: .default, botCount: 2))
    }
    .environmentObject(AppModel(persistence: LocalPersistence(store: InMemoryStore())))
}
