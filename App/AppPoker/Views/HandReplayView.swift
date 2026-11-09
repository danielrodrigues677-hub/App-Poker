import SwiftUI
import GameEngine

struct HandReplayView: View {
    let replay: HandReplay
    @State private var streetIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mão #\(replay.handNumber)")
                    .font(.title3.weight(.bold))
                Text("Blinds \(replay.smallBlind)/\(replay.bigBlind) · \(replay.resultSummary)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !replay.humanHoleCards.isEmpty {
                HStack(spacing: 8) {
                    Text("Suas cartas")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(replay.humanHoleCards.enumerated()), id: \.offset) { _, card in
                        CartaView(card: card, size: .hole)
                    }
                }
            }

            if !replay.streets.isEmpty {
                let snap = replay.streets[min(streetIndex, replay.streets.count - 1)]
                VStack(alignment: .leading, spacing: 10) {
                    Text(snap.street.nomePT)
                        .font(.headline)

                    FeltBoard(
                        communityCards: snap.communityCards,
                        emptyLabel: "Pré-flop — sem comunitárias"
                    )
                    .padding(.horizontal, -AppTheme.horizontalPadding)

                    HStack {
                        Button("Anterior") {
                            streetIndex = max(0, streetIndex - 1)
                        }
                        .disabled(streetIndex == 0)
                        .frame(minHeight: 44)

                        Spacer()
                        Text("\(streetIndex + 1)/\(replay.streets.count)")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()

                        Button("Próxima") {
                            streetIndex = min(replay.streets.count - 1, streetIndex + 1)
                        }
                        .disabled(streetIndex >= replay.streets.count - 1)
                        .frame(minHeight: 44)
                    }
                }
            }

            Text("Ações")
                .font(.headline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(replay.actions.enumerated()), id: \.offset) { _, action in
                        let highlight = streetForHighlight(action.street)
                        HStack(alignment: .top, spacing: 8) {
                            Text(action.street.nomePT)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 72, alignment: .leading)
                            Text("\(action.playerName): \(action.action.nomePT)")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            Text("pote \(action.potAfter)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(highlight ? Color.orange.opacity(0.14) : Color.primary.opacity(0.04))
                        )
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppTheme.horizontalPadding)
        .navigationTitle("Replay")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func streetForHighlight(_ street: Street) -> Bool {
        guard !replay.streets.isEmpty else { return false }
        return replay.streets[min(streetIndex, replay.streets.count - 1)].street == street
    }
}
