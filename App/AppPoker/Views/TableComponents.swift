import SwiftUI
import GameEngine

struct JogadorLinha: View {
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
                    if player.stack == 0 && player.isFolded {
                        Text("out").font(.caption2).foregroundStyle(.red)
                    }
                }
                Text(statusTexto)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if player.kind == .human {
                HStack(spacing: 4) {
                    ForEach(Array(player.holeCards.enumerated()), id: \.offset) { _, c in
                        CartaView(card: c, compact: true)
                    }
                }
            } else if !player.isFolded && player.stack > 0 {
                HStack(spacing: 4) {
                    ForEach(0 ..< min(2, max(player.holeCards.count, 2)), id: \.self) { _ in
                        CartaVerso(compact: true)
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
        .opacity(player.isFolded || player.stack == 0 ? 0.45 : 1)
    }

    private var statusTexto: String {
        if player.stack == 0 { return "eliminado" }
        if player.isFolded { return "fold" }
        if player.isAllIn { return "all-in · aposta \(player.betThisStreet)" }
        if player.betThisStreet > 0 { return "aposta \(player.betThisStreet)" }
        return "na mão"
    }
}

struct AcoesBar: View {
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

struct CartaView: View {
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

struct CartaVerso: View {
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
