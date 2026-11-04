import SwiftUI

struct ComingSoonView: View {
    let titulo: String
    let detalhe: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(titulo)
                .font(.title2.weight(.semibold))
            Text(detalhe)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Em breve")
        .navigationBarTitleDisplayMode(.inline)
    }
}
