import SwiftUI
import Coach

struct TutorialView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private var pages: [TutorialPage] { CoachContent.tutorialPaginas }

    var body: some View {
        ZStack {
            AppTheme.screenGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 24)

                Text("Tutorial")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text(pages[page].titulo)
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .minimumScaleFactor(0.85)
                    .accessibilityAddTraits(.isHeader)

                ScrollView {
                    Text(pages[page].corpo)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: 280)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    ForEach(0 ..< pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.white : Color.white.opacity(0.35))
                            .frame(width: i == page ? 18 : 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Página \(page + 1) de \(pages.count)")

                Button(page == pages.count - 1 ? "Começar a jogar" : "Próximo") {
                    if page == pages.count - 1 {
                        onFinish()
                    } else {
                        page += 1
                    }
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppTheme.thumbButtonMinHeight)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentGreen)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
    }
}
