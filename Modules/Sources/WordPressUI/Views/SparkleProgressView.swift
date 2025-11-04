import SwiftUI
import DesignSystem

public struct SparkleProgressView: View {
    public var height: CGFloat
    @State private var isAnimating = false

    public init(height: CGFloat = 24) {
        self.height = height
    }

    public var body: some View {
        ScaledImage("sparkle", height: height)
            .foregroundStyle(Color.secondary)
            .opacity(isAnimating ? 0.6 : 1.0)
            .scaleEffect(isAnimating ? 0.9 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
    }
}
