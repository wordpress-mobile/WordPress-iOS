import SwiftUI

public struct ShimmerEffect: ViewModifier {

    @State
    private var isAnimating: Bool = false

    let duration: TimeInterval
    let delay: TimeInterval

    init(duration: TimeInterval = 1.5, delay: TimeInterval = 0.25) {
        self.duration = duration
        self.delay = delay

    }

    public func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.4),
                        Color.gray,
                        Color.gray.opacity(0.1)],
                    startPoint: (isAnimating ? UnitPoint(x: -0.3, y: -0.3) : UnitPoint(x: 1, y: 1)),
                    endPoint: (isAnimating ? UnitPoint(x: 0, y: 0) : UnitPoint(x: 1.3, y: 1.3))
                )
            }
            .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))
            .animation(.easeInOut(duration: self.duration).delay(self.delay).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear() {
                isAnimating = true
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("Thinking...")
            .font(.largeTitle)
            .fontWeight(.bold)
            .shimmer()
            .foregroundStyle(.gray)

        Text("Thinking...")
            .font(.title2)
            .fontWeight(.semibold)
            .shimmer()
            .foregroundStyle(.orange)

        Text("Thinking...")
            .font(.body)
            .fontWeight(.bold)
            .shimmer()
            .foregroundStyle(.blue)

        Text("Thinking...")
            .font(.body)
            .shimmer()
            .foregroundStyle(.pink)

        Text("Thinking...")
            .font(.caption)
            .shimmer()
            .foregroundStyle(.green)
    }
}
