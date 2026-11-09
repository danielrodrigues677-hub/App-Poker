import SwiftUI
import Persistence
import GameEngine

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.22, blue: 0.14),
                        Color(red: 0.04, green: 0.12, blue: 0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    VStack(spacing: 8) {
                        Text("App Poker")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Texas Hold'em para iniciantes — 100% grátis")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        NavigationLink {
                            CashSetupView()
                        } label: {
                            Label("Cash", systemImage: "suit.spade.fill")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.20, green: 0.55, blue: 0.32))

                        NavigationLink {
                            SNGSetupView()
                        } label: {
                            Label("Torneio Sit & Go", systemImage: "trophy")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.85))

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Ajustes / Ajuda", systemImage: "gearshape")
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppModel(persistence: LocalPersistence(store: InMemoryStore())))
}
