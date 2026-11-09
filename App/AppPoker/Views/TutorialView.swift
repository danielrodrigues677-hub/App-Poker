import SwiftUI
import Coach

struct TutorialView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private var pages: [TutorialPage] { CoachContent.tutorialPaginas }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.22, blue: 0.14),
                    Color(red: 0.04, green: 0.12, blue: 0.08),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Text(pages[page].titulo)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(pages[page].corpo)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Spacer()

                HStack(spacing: 8) {
                    ForEach(0 ..< pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.white : Color.white.opacity(0.35))
                            .frame(width: 8, height: 8)
                    }
                }

                Button(page == pages.count - 1 ? "Começar a jogar" : "Próximo") {
                    if page == pages.count - 1 {
                        onFinish()
                    } else {
                        page += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.20, green: 0.55, blue: 0.32))
                .padding(.bottom, 36)
            }
        }
    }
}
