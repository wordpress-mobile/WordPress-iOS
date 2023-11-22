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
        Button {
            action()
        } label: {
            if style == .tertiary {
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
                Text(title)
                    .foregroundStyle(
                        style.foregroundColor
                            .opacity(foregroundOpacity))
                    .font(
                        style == .tertiary
                        ? .DS.Body.small
                        : .DS.Body.Emphasized.small
                    )
            }
        }
        .frame(height: Length.Padding.max)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
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

        if style == .primary {
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
                style: .primary,
                action: {
                    ()
                }
            )
            .padding(.horizontal, Length.Padding.large)
        }
    }
}
