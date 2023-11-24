import SwiftUI

public struct DSButton: View {
    @SwiftUI.Environment(\.isEnabled) private var isEnabled
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
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
                buttonText
                    .foregroundStyle(
                        style.foregroundColor
                            .opacity(foregroundOpacity)
                    )
                    .padding(
                        .horizontal,
                        style.size == .small
                        ? Length.Padding.split
                        : Length.Padding.medium
                    )
            }
        }
        .frame(
            height: style.size == .small
            ? Length.Padding.large
            : Length.Padding.max
        )
    }

    private var buttonText: some View {
        switch style.size {
        case .large:
            switch style.emphasis {
            case .primary, .secondary:
                return Text(title)
                    .style(.bodyLarge(.emphasized))
            case .tertiary:
                return Text(title)
                    .style(.bodyLarge(.regular))
            }
        case .medium:
            switch style.emphasis {
            case .primary, .secondary:
                return Text(title)
                    .style(.bodyMedium(.emphasized))
            case .tertiary:
                return Text(title)
                    .style(.bodyMedium(.regular))
            }
        case .small:
            switch style.emphasis {
            case .primary, .secondary:
                return Text(title)
                    .style(.bodySmall(.emphasized))
            case .tertiary:
                return Text(title)
                    .style(.bodySmall(.regular))
            }
        }
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


struct DSButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.DS.Background.primary
                .ignoresSafeArea()
            DSButton(
                title: "Get Domain",
                style: .init(emphasis: .primary, size: .large),
                action: {
                    ()
                }
            )
            .padding(.horizontal, Length.Padding.large)
        }
    }
}
