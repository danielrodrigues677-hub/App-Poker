import SwiftUI
import GameEngine

struct SNGSetupView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var format: SNGFormat = .sixMax

    var body: some View {
        Form {
            Section("Formato") {
                Picker("Assentos", selection: $format) {
                    ForEach(SNGFormat.allCases) { item in
                        Text(item.rotuloPT).tag(item)
                    }
                }
                .pickerStyle(.inline)

                Text("1 mesa · \(format.botCount) bots · stack inicial 1.500 · blinds sobem no tempo. Sem MTT e sem dinheiro real.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Blinds") {
                ForEach(BlindSchedule.padrao.prefix(6)) { level in
                    Text("\(level.rotuloPT) · \(level.durationSeconds)s")
                        .font(.subheadline)
                }
                Text("… e sobem até restar 1 vencedor.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    TournamentTableView(config: SNGConfig(format: format))
                } label: {
                    Text("Entrar no Sit & Go")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Torneio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            format = appModel.preferences.preferredSNGFormat
        }
        .onChange(of: format) { _, newValue in
            appModel.preferences.preferredSNGFormat = newValue
            appModel.savePreferences()
        }
    }
}

#Preview {
    NavigationStack { SNGSetupView() }
        .environmentObject(AppModel(persistence: .shared))
}
