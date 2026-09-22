import SwiftUI

/// A row of the conversations list, with the status, title, time of the last update, and description.
struct UnifiedSupportConversationRow: View {

    let conversation: UnifiedSupportConversationSummary

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ChipView(string: conversation.status.title, color: conversation.status.color)
                .controlSize(.mini)

            titleAndTime

            if let description = conversation.displayDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var titleAndTime: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))

        return layout {
            Text(conversation.displayTitle)
                .font(.headline)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)

            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(UnifiedSupportRelativeTime.format(conversation.updatedAt, relativeTo: context.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    List(UnifiedSupportConversation.previewConversations) { conversation in
        UnifiedSupportConversationRow(conversation: conversation.summary)
    }
    .listStyle(.plain)
}
