import SwiftUI
import GameEngine

/// Tokens visuais compartilhados (iPhone portrait, PT-BR).
enum AppTheme {
    static let feltDeep = Color(red: 0.07, green: 0.22, blue: 0.14)
    static let feltMid = Color(red: 0.12, green: 0.38, blue: 0.22)
    static let feltDark = Color(red: 0.04, green: 0.12, blue: 0.08)
    static let accentGreen = Color(red: 0.20, green: 0.55, blue: 0.32)
    static let potGold = Color(red: 0.95, green: 0.78, blue: 0.28)
    static let coachBg = Color(red: 0.98, green: 0.92, blue: 0.55).opacity(0.22)
    static let coachBorder = Color(red: 0.85, green: 0.70, blue: 0.15).opacity(0.45)

    static let screenGradient = LinearGradient(
        colors: [feltDeep, feltDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Altura mínima confortável para polegar (acima dos 44 pt da HIG).
    static let thumbButtonMinHeight: CGFloat = 52
    static let horizontalPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
}

struct CoachBanner: View {
    let tip: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(.yellow.opacity(0.9))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Dica do coach")
                    .font(.subheadline.weight(.semibold))
                Text(tip)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.coachBg)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.coachBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

struct MesaInfoBar: View {
    let street: String
    let pot: Int
    let handNumber: Int
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            infoChip(titulo: "Street", valor: street)
            Spacer(minLength: 4)
            VStack(spacing: 2) {
                Text("POTE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.potGold.opacity(0.9))
                Text("\(pot)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .overlay(Capsule().strokeBorder(AppTheme.potGold.opacity(0.55), lineWidth: 1))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Pote \(pot)")
            Spacer(minLength: 4)
            if let trailing {
                infoChip(titulo: "Info", valor: trailing)
            } else {
                infoChip(titulo: "Mão", valor: "#\(handNumber)")
            }
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
    }

    private func infoChip(titulo: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titulo.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(valor)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minWidth: 64, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct FeltBoard: View {
    let communityCards: [Card]
    var emptyLabel: String = "Aguardando flop…"

    var body: some View {
        VStack(spacing: 10) {
            if communityCards.isEmpty {
                Text(emptyLabel)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(communityCards.enumerated()), id: \.offset) { _, card in
                        CartaView(card: card, size: .board)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.feltMid,
                            Color(red: 0.09, green: 0.30, blue: 0.18),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppTheme.horizontalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            communityCards.isEmpty
                ? emptyLabel
                : "Cartas comunitárias: " + communityCards.map(\.rotuloPT).joined(separator: ", ")
        )
    }
}
