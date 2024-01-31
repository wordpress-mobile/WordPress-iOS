import SwiftUI

public struct DSButton: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    private let title: String
    private let style: DSButtonStyle
    @Binding private var isLoading: Bool
    private let action: (() -> Void)

    public init(
        title: String,
        style: DSButtonStyle,
        isLoading: Binding<Bool> = .constant(false),
        action: @escaping () -> Void
    ) {
        self._isLoading = isLoading
        self.action = action
        self.title = title
        self.style = style
    }

    public var body: some View {
        switch style.size {
        case .large:
            button
        case .medium, .small:
            button
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var button: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            if style.emphasis == .tertiary {
                buttonContent
            } else {
                buttonContent
                    .contentShape(
                        RoundedRectangle(
                            cornerRadius: Length.Radius.small
                        )
                    )
            }
        }
        .buttonStyle(ScalingButtonStyle(style: style))
        .disabled(isLoading)
    }

    private var buttonContent: some View {
        ZStack {
            buttonBackground
            if isLoading {
                ProgressView()
                    .tint(Color.white)
            } else {
                if style.emphasis != .tertiary {
                    buttonText
                        .padding(
                            .horizontal,
                            style.size == .small
                            ? Length.Padding.split
                            : Length.Padding.medium
                        )
                } else {
                    buttonText
                }
            }
        }
        .frame(
            height: style.size == .small
            ? Length.Padding.large
            : Length.Padding.max
        )
    }

    private var buttonText: some View {
        let textStyle: (TextStyle.Weight) -> TextStyle
        let weight: TextStyle.Weight
        switch style.size {
        case .large:
            textStyle = TextStyle.bodyLarge
        case .medium:
            textStyle = TextStyle.bodyMedium
        case .small:
            textStyle = TextStyle.bodySmall
        }
        switch style.emphasis {
        case .primary, .secondary:
            weight = .emphasized
        case .tertiary:
            weight = .regular
        }
        return Text(title).style(textStyle(weight))
            .foregroundStyle(
                style.foregroundColor
                    .opacity(foregroundOpacity)
            )
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style.emphasis {
        case .primary:
            RoundedRectangle(cornerRadius: Length.Radius.small)
                .fill(style.backgroundColor.opacity(priamryDisabledOpacity))
        case .secondary:
            RoundedRectangle(cornerRadius: Length.Radius.small)
                .stroke(Color.DS.divider, lineWidth: 1)
                .background(Color.clear)

        case .tertiary:
            Color.clear
        }
    }

    private var foregroundOpacity: CGFloat {
        if isEnabled {
            return 1
        }

        if style.emphasis == .primary {
            return 1
        }

        return disabledOpacity
    }

    private var priamryDisabledOpacity: CGFloat {
        isEnabled ? 1 : disabledOpacity
    }

    private var disabledOpacity: CGFloat {
        colorScheme == .light ? 0.5 : 0.6
    }
}

#if DEBUG
struct DSButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.DS.Background.primary
                .ignoresSafeArea()
            DSButton(
                title: "Get Domain",
                style: .init(emphasis: .primary, size: .large, isJetpack: true),
                action: {
                    ()
                }
            )
            .padding(.horizontal, Length.Padding.large)
        }
    }
}
#endif
