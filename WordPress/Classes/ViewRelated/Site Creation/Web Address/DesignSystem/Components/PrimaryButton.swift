import SwiftUI

public struct PrimaryButton: View {
    @SwiftUI.Environment(\.isEnabled) private var isEnabled
    @Binding private var isLoading: Bool
    private let title: String
    private let action: (() -> Void)

    public init(
        isLoading: Binding<Bool> = .constant(false),
        title: String,
        action: @escaping () -> Void
    ) {
        self._isLoading = isLoading
        self.action = action
        self.title = title
    }

    public var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Length.Radius.medium)
                    .fill(isEnabled ? Color.DS.Background.brand : Color.DS.Background.quaternary)
                if isLoading {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text(title)
                        .foregroundStyle(Color.white)
                        .font(.body.weight(.semibold))
                }
            }
            .frame(height: Length.Padding.max)
        }
        .buttonStyle(ScalingPrimaryButtonStyle())
        .disabled(isLoading)
    }
}

private struct ScalingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeIn(duration: 0.15), value: configuration.isPressed)
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemMint)
            PrimaryButton(isLoading: .constant(true), title: "Get Domain") {
                ()
            }
            .padding(.horizontal, Length.Padding.large)
        }
    }
}
