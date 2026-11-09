import SwiftUI
import Persistence
import GameEngine

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 36)

                    VStack(spacing: 10) {
                        Text("App Poker")
                            .font(.largeTitle.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)

                        Text("Texas Hold'em para quem está começando.\nCash e Sit & Go contra bots — 100% grátis, sem dinheiro real.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink {
                            CashSetupView()
                        } label: {
                            homeCard(
                                titulo: "Cash",
                                subtitulo: "Blinds fixos · jogue no seu ritmo",
                                icone: "suit.spade.fill",
                                destaque: true
                            )
                        }

                        NavigationLink {
                            SNGSetupView()
                        } label: {
                            homeCard(
                                titulo: "Torneio Sit & Go",
                                subtitulo: "1 mesa · blinds sobem · last player standing",
                                icone: "trophy.fill",
                                destaque: false
                            )
                        }

                        NavigationLink {
                            SettingsView()
                        } label: {
                            homeCard(
                                titulo: "Ajustes e ajuda",
                                subtitulo: "Coach, tutorial e glossário",
                                icone: "gearshape.fill",
                                destaque: false,
                                compacto: true
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func homeCard(
        titulo: String,
        subtitulo: String,
        icone: String,
        destaque: Bool,
        compacto: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icone)
                .font(compacto ? .title3 : .title2)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(titulo)
                    .font((compacto ? Font.body : Font.title3).weight(.semibold))
                    .fontDesign(.rounded)
                Text(subtitulo)
                    .font(.callout)
                    .opacity(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .opacity(0.55)
                .accessibilityHidden(true)
        }
        .foregroundStyle(destaque ? Color.white : Color.white.opacity(0.92))
        .padding(.horizontal, 18)
        .padding(.vertical, compacto ? 14 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(destaque ? AppTheme.accentGreen : Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(destaque ? 0 : 0.18), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AppModel(persistence: LocalPersistence(store: InMemoryStore())))
}
