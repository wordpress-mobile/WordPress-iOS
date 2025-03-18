import SwiftUI
import BuildSettingsKit

public struct DSButtonStyle {
    public enum Emphasis: CaseIterable {
        case primary
        case secondary
        case tertiary
    }

    public enum Size: CaseIterable {
        case large
        case medium
        case small
    }

    public let emphasis: Emphasis
    public let size: Size
    public let isJetpack: Bool

    public init(
        emphasis: Emphasis,
        size: Size,
        isJetpack: Bool = BuildSettings.current.brand == .jetpack
    ) {
        self.emphasis = emphasis
        self.size = size
        self.isJetpack = isJetpack
    }
}

// MARK: - SwiftUI.Button DSButtonStyle helpers
extension DSButtonStyle {
    var foregroundColor: Color {
        return switch self.emphasis {
        case .primary: Color(.systemBackground)
        case .secondary: Color(.label)
        case .tertiary: .accentColor
        }
    }

    var backgroundColor: Color {
        return switch self.emphasis {
        case .primary: Color(.label)
        case .secondary: Color(.secondarySystemBackground)
        case .tertiary: .clear
        }
    }
}

public struct ScalingButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    private let style: DSButtonStyle

    public init(style: DSButtonStyle) {
        self.style = style
    }

    private var pressedStateBrightness: CGFloat {
        colorScheme == .light ? 0.2 : -0.1
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect((configuration.isPressed && style.emphasis != .tertiary) ? 0.98 : 1)
            .brightness(
                (configuration.isPressed && style.emphasis != .secondary) ? pressedStateBrightness : 0
            )
            .animation(.linear(duration: 0.15), value: configuration.isPressed)
    }
}
