import SwiftUI

struct CompositionView: View {

    private let cornerSize: CGSize = CGSize(width: 9, height: 8)

    @State
    var text = ""

    @State
    var disabled: Bool = false

    @FocusState
    private var textFieldIsFocused: Bool

    var action: (String) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {

            if #available(iOS 26.0, *) {
                self.textField
                    .glassEffect()
            } else {
                self.textField
                    .cornerRadius(self.cornerSize.width)
                    .background(Color(.systemGray4).opacity(0.95))
                    .clipShape(RoundedRectangle(cornerSize: self.cornerSize))
            }

            Button(action: {
                let copy = self.text
                self.text = ""
                self.textFieldIsFocused = false
                self.action(copy)
            }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerSize: self.cornerSize))
            }
            .disabled(self.disabled || self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    var textField: some View {
        TextField("Ask anything...", text: self.$text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .focused($textFieldIsFocused)
    }
}

#Preview {
    NavigationView {
        VStack {
            Spacer()
            CompositionView { message in
                debugPrint(message)
                // Do nothing
            }
        }
    }
}

#Preview {
    NavigationView {
        ZStack {
            List(SupportDataProvider.botConversation.messages) {
                Text($0.text)
            }
            VStack {
                Spacer()
                CompositionView { message in
                    // Do nothing
                }
            }
        }
    }
}
