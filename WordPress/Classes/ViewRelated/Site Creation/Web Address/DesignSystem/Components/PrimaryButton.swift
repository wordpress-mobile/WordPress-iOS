import SwiftUI

public struct PrimaryButton: View {
    private let action: (() -> Void)
    private let title: String

    public init(title: String, action: @escaping () -> Void) {
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
                Text(title)
                    .foregroundStyle(Color.DS.Background.primary)
            }
            .frame(height: 50)
        }

    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemMint)
            PrimaryButton(title: "Get Domain") {
                ()
            }
            .padding(.horizontal, Length.Padding.small)
        }
    }
}
