import SwiftUI

public struct DSButton: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    private let title: String
    private let iconName: IconName?
    private let style: DSButtonStyle
    @Binding private var isLoading: Bool
    private let action: (() -> Void)

    public init(
        title: String,
        iconName: IconName? = nil,
        style: DSButtonStyle,
        isLoading: Binding<Bool> = .constant(false),
        action: @escaping () -> Void
    ) {
        self._isLoading = isLoading
        self.action = action
        self.title = title
        self.iconName = iconName
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
                            cornerRadius: .DS.Radius.small
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
                    buttonLabel
                        .padding(
                            .horizontal,
                            style.size == .small
                            ? .DS.Padding.split
                            : .DS.Padding.medium
                        )
                } else {
                    buttonLabel
                }
            }
        }
        .frame(
            height: style.size == .small
            ? .DS.Padding.large
            : .DS.Padding.max
        )
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let iconName {
            HStack(alignment: .center, spacing: .DS.Padding.half) {
                Image.DS.icon(named: iconName)
                    .imageScale(.small)
                    .foregroundStyle(style.foregroundColor)
                buttonText
            }
        } else {
            buttonText
        }
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
            RoundedRectangle(cornerRadius: .DS.Radius.small)
                .fill(style.backgroundColor.opacity(primaryDisabledOpacity))
        case .secondary:
            RoundedRectangle(cornerRadius: .DS.Radius.small)
                .stroke(style.foregroundColor, lineWidth: 1)
                .background(Color.clear)
        case .tertiary:
            Color.clear
        }
    }

    private var foregroundOpacity: CGFloat {
        if isEnabled {
            return 1
        }

        if style.emphasis == .primary || style.emphasis == .tertiary {
            return 1
        }

        return disabledOpacity
    }

    private var primaryDisabledOpacity: CGFloat {
        isEnabled ? 1 : disabledOpacity
    }

    private var disabledOpacity: CGFloat {
        colorScheme == .light ? 0.2 : 0.3
    }
}

#if DEBUG
struct DSButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            DSButton(
                title: "Get Domain",
                style: .init(emphasis: .primary, size: .large, isJetpack: true),
                action: {
                    ()
                }
            )
            .padding(.horizontal, .DS.Padding.large)
        }
    }
}
#endif
