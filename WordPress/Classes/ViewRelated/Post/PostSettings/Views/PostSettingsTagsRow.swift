import SwiftUI
import WordPressUI
import WordPressData

struct PostSettingsTagsRow: View {
    let tags: [String]

    var body: some View {
        HStack {
            PostSettingsIconView("wpdl-tag")
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.tagsLabel)
                    .font(.body)
                    .foregroundColor(.primary)

                if tags.isEmpty {
                    Text(Strings.addTags)
                        .font(.body)
                        .font(.subheadline)
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    PostSettingsTruncatedArrayTextView(values: tags)
                }
            }

            Spacer()
        }
    }
}

private enum Strings {
    static let tagsLabel = NSLocalizedString(
        "postSettings.tags.label",
        value: "Tags",
        comment: "Label for the tags field. Should be the same as WP core."
    )

    static let addTags = NSLocalizedString(
        "postSettings.tags.addTagsButton",
        value: "Add Tags",
        comment: "Label for the add tags button field. Should be the same as WP core."
    )
}
