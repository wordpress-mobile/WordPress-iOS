import SwiftUI

/// A loading placeholder: a rounded bar with a highlight sweeping across it.
/// Callers size it with `.frame`.
struct ShimmerBar: View {
    var cornerRadius: CGFloat = 4

    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        colors: [.clear, Color(.systemBackground).opacity(0.5), .clear],
                        startPoint: UnitPoint(x: phase, y: 0.5),
                        endPoint: UnitPoint(x: phase + 1, y: 0.5)
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}
