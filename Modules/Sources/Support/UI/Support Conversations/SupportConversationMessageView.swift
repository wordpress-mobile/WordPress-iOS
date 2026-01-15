import SwiftUI

struct SupportConversationMessageView: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(message.authorName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(message.authorIsUser ? .accentColor : .secondary)

                        Spacer()

                        Text(message.createdAt, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }.padding(.bottom)

                    // Message content
                    Text(message.attributedContent)
                        .font(.body)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)

                    // Attachments (if any)
                    if !message.attachments.isEmpty {
                        AttachmentListView(attachments: message.attachments)
                    }
                }
                .padding()
                .background(
                    message.authorIsUser ? Color.accentColor.opacity(0.10) :
                        Color(UIColor.systemGray5))
            }
        }
        .id(message.id)
    }
}
