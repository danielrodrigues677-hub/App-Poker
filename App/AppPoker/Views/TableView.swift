import SwiftUI
import GameEngine
import TableSession

@MainActor
final class TableViewModel: ObservableObject {
    @Published var session: CashTableSession
    @Published var busy = false
    @Published var erro: String?

    init(config: CashConfig) {
        session = CashTableSession(config: config)
        Task { await rodarBotsSePreciso() }
    }

    var state: TableState { session.state }

    func agir(_ action: PlayerAction) {
        guard !busy else { return }
        do {
            try session.applyHuman(action)
            erro = nil
            Task { await rodarBotsSePreciso() }
        } catch {
            erro = error.localizedDescription
        }
    }

    func proximaMao() {
        session.nextHand()
        Task { await rodarBotsSePreciso() }
    }

    private func rodarBotsSePreciso() async {
        busy = true
        defer { busy = false }
        do {
            while session.state.street != .handOver && !session.isHumanTurn {
                try await Task.sleep(nanoseconds: UInt64.random(in: 600_000_000 ... 1_200_000_000))
                _ = try session.stepBot()
            }
        } catch {
            erro = error.localizedDescription
        }
    }
}

struct TableView: View {
    @StateObject private var model: TableViewModel

    init(config: CashConfig) {
        _model = StateObject(wrappedValue: TableViewModel(config: config))
    }

    var body: some View {
        let state = model.state
        VStack(spacing: 12) {
            Text(model.session.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack {
                Text(state.street.nomePT)
                Spacer()
                Text("Pote: \(state.pot)")
                    .fontWeight(.semibold)
                Spacer()
                Text("Mão #\(state.handNumber)")
            }
            .font(.subheadline)
            .padding(.horizontal)

            // Mesa comunitária
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

            if state.street == .handOver {
                Button("Próxima mão") { model.proximaMao() }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
            } else if model.session.isHumanTurn {
                AcoesBar(
                    legal: model.session.legalForHuman,
                    busy: model.busy,
                    onAction: model.agir
                )
                .padding(.bottom, 8)
            } else {
                ProgressView("Bots pensando…")
                    .padding(.bottom)
            }
        }
        .navigationTitle("Mesa cash")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct JogadorLinha: View {
    let player: Player
    let isActor: Bool
    let isDealer: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.name).fontWeight(player.kind == .human ? .bold : .regular)
                    if isDealer {
                        Text("D").font(.caption2.weight(.bold))
                            .padding(4)
                            .background(Circle().fill(.yellow.opacity(0.8)))
                    }
                    if isActor {
                        Text("vez").font(.caption2).foregroundStyle(.orange)
                    }
                }
                Text(statusTexto)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if player.kind == .human || !player.holeCards.isEmpty && player.isFolded == false {
                HStack(spacing: 4) {
                    ForEach(Array(player.holeCards.enumerated()), id: \.offset) { _, c in
                        // Bots: cartas ocultas até showdown simplificado — MVP mostra só do humano
                        if player.kind == .human {
                            CartaView(card: c, compact: true)
                        } else {
                            CartaVerso(compact: true)
                        }
                    }
                }
            }
            Text("\(player.stack)")
                .monospacedDigit()
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(8)
        .background(isActor ? Color.orange.opacity(0.12) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(player.isFolded ? 0.45 : 1)
    }

    private var statusTexto: String {
        if player.isFolded { return "fold" }
        if player.isAllIn { return "all-in · aposta \(player.betThisStreet)" }
        if player.betThisStreet > 0 { return "aposta \(player.betThisStreet)" }
        return "na mão"
    }
}

private struct AcoesBar: View {
    let legal: LegalActions
    let busy: Bool
    let onAction: (PlayerAction) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if legal.canFold {
                    Button("Desistir") { onAction(.fold) }
                        .buttonStyle(.bordered)
                }
                if legal.canCheck {
                    Button("Passar") { onAction(.check) }
                        .buttonStyle(.bordered)
                }
                if legal.canCall {
                    Button("Pagar \(legal.callAmount)") { onAction(.call) }
                        .buttonStyle(.borderedProminent)
                }
            }
            HStack {
                if legal.canRaise {
                    Button("Aumentar \(legal.minRaiseTo)") {
                        onAction(.raise(to: legal.minRaiseTo))
                    }
                    .buttonStyle(.borderedProminent)
                }
                if legal.canAllIn {
                    Button("All-in") { onAction(.allIn) }
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
            }
        }
        .disabled(busy)
        .padding(.horizontal)
    }
}

private struct CartaView: View {
    let card: Card
    var compact: Bool = false

    var body: some View {
        Text(card.description)
            .font(compact ? .caption.monospaced() : .body.monospaced())
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 4 : 8)
            .background(Color.white)
            .foregroundStyle(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct CartaVerso: View {
    var compact: Bool = false
    var body: some View {
        Text("🂠")
            .font(compact ? .caption : .body)
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 4 : 8)
            .background(Color.blue.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    NavigationStack {
        TableView(config: CashConfig(preset: .default, botCount: 2))
    }
}
