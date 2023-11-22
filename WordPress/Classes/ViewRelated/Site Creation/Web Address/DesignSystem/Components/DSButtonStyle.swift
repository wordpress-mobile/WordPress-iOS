import SwiftUI

public enum DSButtonStyle {
    case primary
    case secondary
    case tertiary
}

// MARK: - SwiftUI.Button DSButtonStyle helpers
extension DSButtonStyle {
    var foregroundColor: Color {
        switch self {
        case .primary:
            return .DS.Background.primary
        case .secondary:
            return .DS.Foreground.primary
        case .tertiary:
            return .DS.Foreground.brand
        }
    }

    var backgroundColor: Color {
        switch self {
        case .primary:
            return .DS.Foreground.primary
        case .secondary, .tertiary:
            return .clear
        }
    }
}

public struct ScalingButtonStyle: ButtonStyle {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    private let style: DSButtonStyle

    public init(style: DSButtonStyle) {
        self.style = style
    }

    private var pressedStateBrightness: CGFloat {
        colorScheme == .light ? 0.2 : -0.1
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect((configuration.isPressed && style != .tertiary) ? 0.98 : 1)
            .brightness(
                (configuration.isPressed && style != .secondary) ? pressedStateBrightness : 0
            )
            .animation(.easeIn(duration: 0.15), value: configuration.isPressed)
    }
}
