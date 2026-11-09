import SwiftUI
import Coach
import Persistence
import GameEngine

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Form {
            Section {
                Toggle("Dicas do coach", isOn: Binding(
                    get: { appModel.preferences.coachEnabled },
                    set: { appModel.setCoachEnabled($0) }
                ))
                .font(.body)
            } header: {
                Text("Coach")
            } footer: {
                Text("Ligado no primeiro uso. Mostra dicas curtas antes da sua vez — não joga por você.")
                    .font(.footnote)
            }

            Section("Aprender") {
                NavigationLink {
                    GlossaryView()
                } label: {
                    Label("Glossário", systemImage: "book")
                }
                NavigationLink {
                    TutorialView {
                        appModel.completeTutorial()
                    }
                } label: {
                    Label("Ver tutorial de novo", systemImage: "hand.raised")
                }
            }

            Section("Última mão") {
                if let replay = appModel.persistence.loadLastReplay() {
                    NavigationLink {
                        HandReplayView(replay: replay)
                    } label: {
                        Text("Replay mão #\(replay.handNumber)")
                            .font(.body)
                    }
                } else {
                    Text("Nenhum replay salvo ainda. Jogue uma mão para ver o histórico aqui.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Sessões recentes") {
                let sessions = appModel.persistence.loadSessions()
                if sessions.isEmpty {
                    Text("Nenhuma sessão salva.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions.prefix(8)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.detailPT)
                                .font(.body)
                            Text(item.kind.uppercased())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                Text("Idioma: português (PT-BR)")
                    .font(.body)
                Text("Monetização: 100% grátis")
                    .font(.body)
            } header: {
                Text("Sobre")
            } footer: {
                Text("Sem multiplayer, MTT ou dinheiro real no V1.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GlossaryView: View {
    var body: some View {
        List(CoachContent.glossario) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.termo)
                    .font(.headline)
                Text(entry.definicao)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
        }
        .navigationTitle("Glossário")
        .navigationBarTitleDisplayMode(.inline)
    }
}
