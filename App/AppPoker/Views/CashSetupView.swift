import SwiftUI
import GameEngine

struct CashSetupView: View {
    @State private var preset: BlindPreset = .default
    @State private var botCount: Int = 5

    var body: some View {
        Form {
            Section("Blinds / buy-in") {
                Picker("Preset", selection: $preset) {
                    ForEach(BlindPreset.all) { item in
                        Text(item.rotuloPT).tag(item)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Oponentes") {
                Stepper(value: $botCount, in: 1 ... 9) {
                    Text("\(botCount) bot\(botCount == 1 ? "" : "s") · \(botCount + 1) assentos")
                }
                Text("Mesa solo contra bots (sem multiplayer).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    TableView(config: CashConfig(preset: preset, botCount: botCount))
                } label: {
                    Text("Sentar na mesa")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Cash")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { CashSetupView() }
}
