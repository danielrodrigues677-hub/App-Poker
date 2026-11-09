import SwiftUI
import GameEngine

struct CashSetupView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var preset: BlindPreset = .default
    @State private var botCount: Int = 5

    var body: some View {
        Form {
            Section {
                Text("Escolha blinds e quantos oponentes. Você joga solo contra bots — sem multiplayer e sem dinheiro real.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                Picker("Preset de blinds", selection: $preset) {
                    ForEach(BlindPreset.all) { item in
                        Text(item.rotuloPT).tag(item)
                    }
                }
                .pickerStyle(.inline)

                LabeledContent("Buy-in") {
                    Text("\(preset.buyIn) fichas")
                        .font(.body.monospacedDigit().weight(.medium))
                }
            } header: {
                Text("Blinds e buy-in")
            } footer: {
                Text("Buy-in padrão = 100 big blinds. Ideal para aprender sem pressão.")
                    .font(.footnote)
            }

            Section {
                Stepper(value: $botCount, in: 1 ... 9) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(botCount) oponente\(botCount == 1 ? "" : "s")")
                            .font(.body.weight(.medium))
                        Text("\(botCount + 1) assentos na mesa (você + bots)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Oponentes")
            }

            Section {
                NavigationLink {
                    TableView(config: CashConfig(preset: preset, botCount: botCount))
                } label: {
                    Text("Sentar na mesa")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            } footer: {
                Text("Dica: com o coach ligado (Ajustes), você recebe sugestões antes de cada ação.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Cash")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let match = BlindPreset.all.first(where: { $0.id == appModel.preferences.preferredCashPresetId }) {
                preset = match
            }
            botCount = appModel.preferences.preferredCashBotCount
        }
        .onChange(of: preset) { _, newValue in
            appModel.preferences.preferredCashPresetId = newValue.id
            appModel.savePreferences()
        }
        .onChange(of: botCount) { _, newValue in
            appModel.preferences.preferredCashBotCount = newValue
            appModel.savePreferences()
        }
    }
}

#Preview {
    NavigationStack { CashSetupView() }
        .environmentObject(AppModel(persistence: .shared))
}
