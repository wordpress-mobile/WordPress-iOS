import SwiftUI

/// The field used to write a message to the AI Assistant.
///
/// Unlike `CompositionView`, the text belongs to the view model, so an unsent message can be given back to the user
/// when sending fails.
struct UnifiedSupportComposer: View {

    @Binding var text: String

    let isSendEnabled: Bool
    let send: () -> Void

    @FocusState private var isFocused: Bool

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            textField
            sendButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var textField: some View {
        let field = TextField(UnifiedSupportLocalization.messagePlaceholder, text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .focused($isFocused)
            .submitLabel(.send)
            .onSubmit(sendIfPossible)

        // A rounded rectangle rather than the default capsule: its corners would eat into the text once the
        // message takes more than one line.
        if #available(iOS 26.0, *) {
            field.glassEffect(.regular, in: shape)
        } else {
            field
                .background(Color(.systemGray6))
                .clipShape(shape)
        }
    }

    private var sendButton: some View {
        Button(action: sendIfPossible) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSendEnabled ? Color.white : Color(.systemGray6))
                .frame(width: 36, height: 36)
                .background(isSendEnabled ? Color.accentColor : Color(.systemGray3))
                .clipShape(Circle())
        }
        .disabled(!isSendEnabled)
        .accessibilityLabel(UnifiedSupportLocalization.sendMessage)
    }

    private func sendIfPossible() {
        guard isSendEnabled else {
            return
        }
        isFocused = false
        send()
    }
}

#Preview {
    @Previewable @State var text = ""

    VStack {
        Spacer()
        UnifiedSupportComposer(text: $text, isSendEnabled: !text.isEmpty) {
            text = ""
        }
    }
}
