import SwiftUI

struct MessageView: View {
    let message: BotMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isWrittenByUser {
                Spacer()
            }

            VStack(alignment: message.isWrittenByUser ? .trailing : .leading, spacing: 4) {
                Text(message.attributedText)
                    .padding(12)
                    .background(message.isWrittenByUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(message.isWrittenByUser ? .white : .primary)
                    .cornerRadius(16)

                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            }
            .padding(.vertical, 4)

            if !message.isWrittenByUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    MessageView(message: BotMessage(id: 1234, text: "Hello World", date: Date().addingTimeInterval(-423432), userWantsToTalkToHuman: false, isWrittenByUser: true))
    MessageView(message: BotMessage(id: 5678, text: "Hello back, how are you doing?", date: Date(), userWantsToTalkToHuman: false, isWrittenByUser: false))
}
