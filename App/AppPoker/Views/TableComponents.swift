import SwiftUI
import GameEngine

enum CartaSize {
    case board
    case hole
    case compact

    var width: CGFloat {
        switch self {
        case .board: return 52
        case .hole: return 48
        case .compact: return 34
        }
    }

    var height: CGFloat {
        switch self {
        case .board: return 72
        case .hole: return 66
        case .compact: return 48
        }
    }

    var rankFont: Font {
        switch self {
        case .board: return .title2.weight(.bold)
        case .hole: return .title3.weight(.bold)
        case .compact: return .caption.weight(.bold)
        }
    }

    var suitFont: Font {
        switch self {
        case .board: return .title3
        case .hole: return .body
        case .compact: return .caption2
        }
    }
}

struct JogadorLinha: View {
    let player: Player
    let isActor: Bool
    let isDealer: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(player.kind == .human ? .body.weight(.bold) : .body.weight(.medium))
                        .lineLimit(1)
                    if isDealer {
                        Text("D")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(5)
                            .background(Circle().fill(AppTheme.potGold))
                            .accessibilityLabel("Dealer")
                    }
                    if isActor {
                        Text("Sua vez")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.orange.opacity(0.9)))
                            .foregroundStyle(.white)
                    }
                }
                Text(statusTexto)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if player.kind == .human {
                HStack(spacing: 4) {
                    ForEach(Array(player.holeCards.enumerated()), id: \.offset) { _, c in
                        CartaView(card: c, size: .compact)
                    }
                }
            } else if !player.isFolded && player.stack > 0 {
                HStack(spacing: 4) {
                    ForEach(0 ..< 2, id: \.self) { _ in
                        CartaVerso(size: .compact)
                    }
                }
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.stack)")
                    .font(.body.monospacedDigit().weight(.semibold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("fichas")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 56, alignment: .trailing)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(player.stack) fichas")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActor ? Color.orange.opacity(0.16) : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isActor ? Color.orange.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
        .opacity(player.isFolded || player.stack == 0 ? 0.5 : 1)
        .accessibilityElement(children: .combine)
    }

    private var statusTexto: String {
        if player.stack == 0 { return "Eliminado" }
        if player.isFolded { return "Desistiu (fold)" }
        if player.isAllIn { return "All-in · aposta \(player.betThisStreet)" }
        if player.betThisStreet > 0 { return "Aposta \(player.betThisStreet)" }
        return "Na mão"
    }
}

struct AcoesBar: View {
    let legal: LegalActions
    let busy: Bool
    let onAction: (PlayerAction) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if legal.canFold {
                    acaoBotao(
                        titulo: "Desistir",
                        subtitulo: "Fold",
                        estilo: .secundario,
                        acao: { onAction(.fold) }
                    )
                }
                if legal.canCheck {
                    acaoBotao(
                        titulo: "Passar",
                        subtitulo: "Check",
                        estilo: .primario,
                        acao: { onAction(.check) }
                    )
                }
                if legal.canCall {
                    acaoBotao(
                        titulo: "Pagar \(legal.callAmount)",
                        subtitulo: "Call",
                        estilo: .primario,
                        acao: { onAction(.call) }
                    )
                }
            }
            HStack(spacing: 10) {
                if legal.canRaise {
                    acaoBotao(
                        titulo: "Aumentar \(legal.minRaiseTo)",
                        subtitulo: "Raise mínimo",
                        estilo: .primario,
                        acao: { onAction(.raise(to: legal.minRaiseTo)) }
                    )
                }
                if legal.canAllIn {
                    acaoBotao(
                        titulo: "All-in",
                        subtitulo: "Todas as fichas",
                        estilo: .perigoso,
                        acao: { onAction(.allIn) }
                    )
                }
            }
        }
        .disabled(busy)
        .padding(.horizontal, AppTheme.horizontalPadding)
        .padding(.top, 4)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
    }

    private enum Estilo { case primario, secundario, perigoso }

    private func acaoBotao(
        titulo: String,
        subtitulo: String,
        estilo: Estilo,
        acao: @escaping () -> Void
    ) -> some View {
        Button(action: acao) {
            VStack(spacing: 2) {
                Text(titulo)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitulo)
                    .font(.caption2)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppTheme.thumbButtonMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .tint(cor(estilo))
        .accessibilityLabel("\(titulo). \(subtitulo)")
    }

    private func cor(_ estilo: Estilo) -> Color {
        switch estilo {
        case .primario: return AppTheme.accentGreen
        case .secundario: return Color.secondary.opacity(0.85)
        case .perigoso: return Color.red.opacity(0.85)
        }
    }
}

struct CartaView: View {
    let card: Card
    var size: CartaSize = .board
    /// Compatibilidade com chamadas antigas `compact: true`.
    var compact: Bool = false

    private var resolved: CartaSize {
        compact ? .compact : size
    }

    private var isRed: Bool {
        card.suit == .hearts || card.suit == .diamonds
    }

    var body: some View {
        VStack(spacing: resolved == .compact ? 0 : 2) {
            Text(card.rank.simbolo)
                .font(resolved.rankFont)
            Text(card.suit.rawValue)
                .font(resolved.suitFont)
        }
        .foregroundStyle(isRed ? Color.red : Color.black)
        .frame(width: resolved.width, height: resolved.height)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .accessibilityLabel(card.rotuloPT)
    }
}

struct CartaVerso: View {
    var size: CartaSize = .compact
    var compact: Bool = false

    private var resolved: CartaSize {
        compact ? .compact : size
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.28, blue: 0.55),
                        Color(red: 0.10, green: 0.18, blue: 0.40),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: resolved.width, height: resolved.height)
            .overlay(
                Image(systemName: "suit.spade.fill")
                    .font(resolved == .compact ? .caption2 : .body)
                    .foregroundStyle(.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .accessibilityLabel("Carta fechada")
    }
}

struct HandOverBar: View {
    let canReplay: Bool
    let onReplay: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if canReplay {
                Button(action: onReplay) {
                    Label("Replay", systemImage: "play.rectangle")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.thumbButtonMinHeight)
                }
                .buttonStyle(.bordered)
            }
            Button(action: onNext) {
                Text("Próxima mão")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppTheme.thumbButtonMinHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accentGreen)
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
        .padding(.bottom, 6)
    }
}
