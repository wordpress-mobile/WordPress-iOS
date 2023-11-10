import SwiftUI

public struct PrimaryButton: View {
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.DS.Background.brand)
                if isLoading {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text(title)
                        .foregroundStyle(Color.white)
                }
            }
            .frame(height: 50)
        }

    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemMint)
            PrimaryButton(isLoading: .constant(true), title: "Get Domain") {
                ()
            }
            .padding(.horizontal, Length.Padding.small)
        }
    }
}
