import SwiftUI
import GameEngine

struct HandReplayView: View {
    let replay: HandReplay
    @State private var streetIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mão #\(replay.handNumber) · blinds \(replay.smallBlind)/\(replay.bigBlind)")
                .font(.headline)

            Text(replay.resultSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !replay.humanHoleCards.isEmpty {
                HStack {
                    Text("Suas cartas:")
                    ForEach(Array(replay.humanHoleCards.enumerated()), id: \.offset) { _, card in
                        CartaView(card: card, compact: true)
                    }
                }
            }

            if !replay.streets.isEmpty {
                let snap = replay.streets[min(streetIndex, replay.streets.count - 1)]
                VStack(alignment: .leading, spacing: 8) {
                    Text("Street: \(snap.street.nomePT)")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 6) {
                        ForEach(Array(snap.communityCards.enumerated()), id: \.offset) { _, card in
                            CartaView(card: card)
                        }
                        if snap.communityCards.isEmpty {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.12, green: 0.38, blue: 0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    HStack {
                        Button("Anterior") {
                            streetIndex = max(0, streetIndex - 1)
                        }
                        .disabled(streetIndex == 0)
                        Spacer()
                        Text("\(streetIndex + 1)/\(replay.streets.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Próxima street") {
                            streetIndex = min(replay.streets.count - 1, streetIndex + 1)
                        }
                        .disabled(streetIndex >= replay.streets.count - 1)
                    }
                }
            }

            Text("Ações")
                .font(.subheadline.weight(.semibold))

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(replay.actions.enumerated()), id: \.offset) { _, action in
                        let highlight = streetForHighlight(action.street)
                        HStack(alignment: .top) {
                            Text(action.street.nomePT)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 64, alignment: .leading)
                            Text("\(action.playerName): \(action.action.nomePT)")
                                .font(.subheadline)
                            Spacer()
                            Text("pote \(action.potAfter)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                        .background(highlight ? Color.orange.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("Replay")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func streetForHighlight(_ street: Street) -> Bool {
        guard !replay.streets.isEmpty else { return false }
        return replay.streets[min(streetIndex, replay.streets.count - 1)].street == street
    }
}
