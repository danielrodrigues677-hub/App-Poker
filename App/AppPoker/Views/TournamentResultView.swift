import SwiftUI
import TableSession
import GameEngine

struct TournamentResultView: View {
    let result: TournamentResult
    let replay: HandReplay?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: result.humanFinished ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 48))
                .foregroundStyle(result.humanFinished ? .yellow : .secondary)

            Text(result.humanFinished ? "Você venceu!" : "Torneio encerrado")
                .font(.title.weight(.bold))

            VStack(spacing: 8) {
                Text("Campeão: \(result.winnerName)")
                Text("Sua colocação: \(result.humanPlace)º")
                Text("Mãos jogadas: \(result.handsPlayed)")
                Text("Nível final de blinds: \(result.finalBlindLevel)")
            }
            .font(.body)
            .foregroundStyle(.secondary)

            Text(result.tipPT)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

            if let replay {
                NavigationLink {
                    HandReplayView(replay: replay)
                } label: {
                    Label("Replay da última mão", systemImage: "play.rectangle")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(.top, 32)
        .navigationTitle("Resultado")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}
