import SwiftUI

/// A message in a conversation with the AI Assistant.
struct UnifiedSupportChatBubble: View {

    let message: UnifiedSupportMessage

    private var isWrittenByUser: Bool {
        message.authorRole == .user
    }

    private var links: [UnifiedSupportAttachment] {
        message.attachments.filter { $0.kind == .link }
    }

    var body: some View {
        VStack(alignment: isWrittenByUser ? .trailing : .leading, spacing: 2) {
            if !isWrittenByUser {
                Text(UnifiedSupportLocalization.statusAIAssistant)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(message.attributedContent)
                    .font(.body)
                    .textSelection(.enabled)

                ForEach(links) { link in
                    UnifiedSupportSourceLink(attachment: link)
                }

                Text(UnifiedSupportRelativeTime.format(message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(isWrittenByUser ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity, alignment: isWrittenByUser ? .trailing : .leading)
        .padding(.leading, isWrittenByUser ? 48 : 0)
        .padding(.trailing, isWrittenByUser ? 0 : 48)
    }
}

/// A page the AI Assistant used to answer.
private struct UnifiedSupportSourceLink: View {

    let attachment: UnifiedSupportAttachment

    @Environment(\.openURL)
    private var openURL

    var body: some View {
        Button {
            openURL(attachment.url)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(attachment.filename)
                    .font(.subheadline)
                    .underline()
                    .multilineTextAlignment(.leading)

                if let matchScore = attachment.matchScore {
                    Text(
                        String.localizedStringWithFormat(
                            UnifiedSupportLocalization.attachmentMatchScore,
                            Int((matchScore * 100).rounded())
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel(
            String.localizedStringWithFormat(UnifiedSupportLocalization.openLink, attachment.filename)
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(UnifiedSupportConversation.previewBotConversation.messages) { message in
                UnifiedSupportChatBubble(message: message)
            }
        }
        .padding()
    }
}
