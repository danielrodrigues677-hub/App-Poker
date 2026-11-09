import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            if appModel.showTutorial {
                TutorialView {
                    appModel.completeTutorial()
                }
            } else {
                HomeView()
            }
        }
    }
}
