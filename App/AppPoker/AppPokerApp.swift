import SwiftUI
import GameEngine
import Persistence

@main
struct AppPokerApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var preferences: AppPreferences
    @Published var showTutorial: Bool
    let persistence: LocalPersistence

    init(persistence: LocalPersistence = .shared) {
        self.persistence = persistence
        let prefs = persistence.loadPreferences()
        self.preferences = prefs
        self.showTutorial = !prefs.tutorialCompleted
    }

    func savePreferences() {
        persistence.savePreferences(preferences)
    }

    func setCoachEnabled(_ enabled: Bool) {
        preferences.coachEnabled = enabled
        savePreferences()
    }

    func completeTutorial() {
        preferences.tutorialCompleted = true
        showTutorial = false
        savePreferences()
    }

    func persistReplay(_ replay: HandReplay?) {
        guard let replay else { return }
        persistence.saveLastReplay(replay)
    }

    func persistSession(_ summary: SessionSummary) {
        persistence.appendSession(summary)
    }
}
