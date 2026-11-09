import SwiftUI
import TableSession
import GameEngine

struct TournamentResultView: View {
    let result: TournamentResult
    let replay: HandReplay?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: result.humanFinished ? "trophy.fill" : "flag.checkered")
                    .font(.system(size: 52))
                    .foregroundStyle(result.humanFinished ? AppTheme.potGold : .secondary)
                    .padding(.top, 24)
                    .accessibilityHidden(true)

                Text(result.humanFinished ? "Você venceu!" : "Torneio encerrado")
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    resultRow(titulo: "Campeão", valor: result.winnerName)
                    resultRow(titulo: "Sua colocação", valor: "\(result.humanPlace)º")
                    resultRow(titulo: "Mãos jogadas", valor: "\(result.handsPlayed)")
                    resultRow(titulo: "Nível final", valor: "\(result.finalBlindLevel)")
                }
                .padding(.horizontal, 8)

                Text(result.tipPT)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.coachBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, AppTheme.horizontalPadding)

                if let replay {
                    NavigationLink {
                        HandReplayView(replay: replay)
                    } label: {
                        Label("Replay da última mão", systemImage: "play.rectangle")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Resultado")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resultRow(titulo: String, valor: String) -> some View {
        HStack {
            Text(titulo)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Text(valor)
                .font(.body.weight(.semibold))
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
        .accessibilityElement(children: .combine)
    }
}
