import SwiftUI
import Coach
import Persistence
import GameEngine

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Form {
            Section("Coach") {
                Toggle("Dicas do coach", isOn: Binding(
                    get: { appModel.preferences.coachEnabled },
                    set: { appModel.setCoachEnabled($0) }
                ))
                Text("Ligado no primeiro uso. Ajuda contextual — não joga por você.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Aprender") {
                NavigationLink("Glossário") {
                    GlossaryView()
                }
                NavigationLink("Ver tutorial de novo") {
                    TutorialView {
                        appModel.completeTutorial()
                    }
                }
            }

            Section("Última mão") {
                if let replay = appModel.persistence.loadLastReplay() {
                    NavigationLink {
                        HandReplayView(replay: replay)
                    } label: {
                        Text("Replay mão #\(replay.handNumber)")
                    }
                } else {
                    Text("Nenhum replay salvo ainda.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Sessões recentes") {
                let sessions = appModel.persistence.loadSessions()
                if sessions.isEmpty {
                    Text("Nenhuma sessão salva.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions.prefix(8)) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.detailPT)
                            Text(item.kind.uppercased())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Sobre") {
                Text("Idioma: português (PT-BR)")
                Text("Monetização: 100% grátis")
                Text("Sem multiplayer, MTT ou dinheiro real no V1.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GlossaryView: View {
    var body: some View {
        List(CoachContent.glossario) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.termo).font(.headline)
                Text(entry.definicao)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Glossário")
        .navigationBarTitleDisplayMode(.inline)
    }
}
