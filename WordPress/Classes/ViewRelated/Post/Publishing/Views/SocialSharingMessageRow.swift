import SwiftUI

struct SocialSharingMessageRow: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text.isEmpty ? Strings.placeholder : text)
                .lineLimit(3)
                .foregroundColor(text.isEmpty ? Color(.tertiaryLabel) : .primary)
                .font(.body)
                .multilineTextAlignment(.leading)

            if !text.isEmpty {
                Text("\(text.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static var localizedPlaceholderText: String {
        Strings.placeholder
    }
}

private enum Strings {
    static let placeholder = NSLocalizedString(
        "prepublishing.socialAccounts.messagePlaceholder",
        value: "Write a brief message to share on social media alognside the post",
        comment: "Placeholder text for the message field in Social Sharing"
    )
}
