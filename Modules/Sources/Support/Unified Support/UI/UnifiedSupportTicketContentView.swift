import SwiftUI

/// A conversation the support team has taken over, shown as a ticket.
struct UnifiedSupportTicketContentView: View {

    @ObservedObject var viewModel: UnifiedSupportConversationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if !viewModel.title.isEmpty {
                Text(viewModel.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityAddTraits(.isHeader)
            }

            ForEach(viewModel.messages) { message in
                if message.authorRole == .system {
                    UnifiedSupportSystemMessage(message: message)
                } else {
                    UnifiedSupportMessageCard(message: message)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            ChipView(string: viewModel.status.title, color: viewModel.status.color)
                .controlSize(.small)

            Spacer(minLength: 8)

            Text(
                String.localizedStringWithFormat(
                    UnifiedSupportLocalization.lastUpdated,
                    UnifiedSupportRelativeTime.format(viewModel.lastActivityAt)
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

/// A message of a ticket, shown as a full width card.
struct UnifiedSupportMessageCard: View {

    let message: UnifiedSupportMessage

    private var isWrittenByUser: Bool {
        message.authorRole == .user
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(message.authorName)
                    .font(.headline)
                    .foregroundStyle(isWrittenByUser ? Color.accentColor : .secondary)

                Spacer(minLength: 8)

                Text(UnifiedSupportRelativeTime.format(message.createdAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(message.attributedContent)
                .font(.body)
                .textSelection(.enabled)

            if !message.attachments.isEmpty {
                UnifiedSupportAttachmentsView(attachments: message.attachments)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(isWrittenByUser ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// The marker the server adds when the AI Assistant hands a conversation to the support team.
struct UnifiedSupportSystemMessage: View {

    let message: UnifiedSupportMessage

    var body: some View {
        HStack(spacing: 8) {
            line
            Text(message.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            line
        }
        .padding(.vertical, 4)
    }

    private var line: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 1)
    }
}

/// Shown at the bottom of a conversation that can't accept replies.
struct UnifiedSupportClosedBanner: View {

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "info.circle")
            Text(UnifiedSupportLocalization.conversationClosed)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(.systemRed))
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemRed).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

/// The button used to answer the support team.
struct UnifiedSupportReplyButton: View {

    let action: UnifiedSupportReplyAction
    let perform: () -> Void

    var body: some View {
        Button(action: perform) {
            Label(action.title, systemImage: "arrowshape.turn.up.left")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
