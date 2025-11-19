import SwiftUI

struct CompositionView: View {

    private let cornerSize: CGSize = CGSize(width: 9, height: 8)

    private let action: (String) -> Void
    private let isDisabled: Bool

    @State
    private var text = ""

    @State
    private var textIsEmpty: Bool = false

    private var sendButtonIsDisabled: Bool {
        self.isDisabled || self.textIsEmpty
    }

    @FocusState
    private var textFieldIsFocused: Bool

    init(isDisabled: Bool, action: @escaping (String) -> Void) {
        self.isDisabled = isDisabled
        self.action = action
    }

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

            Button(action: self.triggerAction) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(self.sendButtonIsDisabled ? Color(.systemGray6) : .white)
                    .frame(width: 32, height: 32)
                    .background(self.sendButtonIsDisabled ? Color(.systemGray3) : Color.accentColor)
                    .clipShape(RoundedRectangle(cornerSize: self.cornerSize))
            }
            .disabled(self.sendButtonIsDisabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onChange(of: self.text, initial: true, { oldValue, newValue in
            withAnimation {
                textIsEmpty = newValue
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            }
        })
    }

    @ViewBuilder
    var textField: some View {
        TextField("Ask anything...", text: self.$text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .focused($textFieldIsFocused)
            .onSubmit(of: .text) {
                self.triggerAction()
            }
    }

    private func triggerAction() {
        guard !self.sendButtonIsDisabled else {
            return
        }

        let copy = self.text
        self.text = ""
        self.textFieldIsFocused = false
        self.action(copy)
    }
}

#Preview {
    NavigationStack {
        VStack {
            Spacer()
            CompositionView(isDisabled: false) { message in
                // Do nothing
            }
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            List(SupportDataProvider.botConversation.messages) {
                Text($0.text)
            }
            VStack {
                Spacer()
                CompositionView(isDisabled: false) { message in
                    // You'd do something with the message if this weren't a preview
                }
            }
        }
    }
}
