import SwiftUI

struct PostSettingExcerptRow: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text.isEmpty ? Strings.excerptPlaceholder : text)
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
        Strings.excerptPlaceholder
    }
}

private enum Strings {
    static let excerptPlaceholder = NSLocalizedString(
        "postSettings.excerpt.placeholder",
        value: "Write a brief summary of your post to appear on blog index, archives, and search results.",
        comment: "Placeholder text for the excerpt field in Post Settings"
    )
}
