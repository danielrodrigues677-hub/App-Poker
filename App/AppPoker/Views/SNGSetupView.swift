import SwiftUI
import GameEngine

struct SNGSetupView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var format: SNGFormat = .sixMax

    var body: some View {
        Form {
            Section {
                Text("Sit & Go de 1 mesa: todos começam juntos, blinds sobem no tempo e o último com fichas vence. Sem MTT e sem dinheiro real.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                Picker("Formato", selection: $format) {
                    ForEach(SNGFormat.allCases) { item in
                        Text(item.rotuloPT).tag(item)
                    }
                }
                .pickerStyle(.inline)

                LabeledContent("Oponentes") {
                    Text("\(format.botCount) bots")
                }
                LabeledContent("Stack inicial") {
                    Text("1.500 fichas")
                        .font(.body.monospacedDigit())
                }
            } header: {
                Text("Formato")
            } footer: {
                Text("6-max é mais rápido para treinar; 10-max parece mais um torneio clássico.")
                    .font(.footnote)
            }

            Section {
                ForEach(BlindSchedule.padrao.prefix(6)) { level in
                    HStack {
                        Text(level.rotuloPT)
                            .font(.body)
                        Spacer()
                        Text("\(level.durationSeconds)s")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Agenda de blinds (início)")
            } footer: {
                Text("Depois os blinds continuam subindo até restar 1 vencedor.")
                    .font(.footnote)
            }

            Section {
                NavigationLink {
                    TournamentTableView(config: SNGConfig(format: format))
                } label: {
                    Text("Entrar no Sit & Go")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
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
