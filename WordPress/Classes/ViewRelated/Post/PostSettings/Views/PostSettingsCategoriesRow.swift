import SwiftUI
import WordPressUI
import WordPressData

// TODO: fix this

//struct PostSettingsCategoriesRow: View {
//    let categories: String
//
//    var body: some View {
//        HStack {
//            ScaledImage("wpdl-category", height: 17)
//                .foregroundColor(.secondary)
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text(Strings.tagsLabel)
//                    .font(.body)
//                    .foregroundColor(.primary)
//
//                let tags = AbstractPost.makeTagsText(tags)
//                if tags.isEmpty {
//                    Text(Strings.addTag)
//                        .font(.body)
//                        .foregroundColor(Color(.tertiaryLabel))
//                } else {
//                    PostSettingsTruncatedArrayTextView(values: tags)
//                }
//            }
//
//            Spacer()
//        }
//    }
//}
//
//private enum Strings {
//    static let tagsLabel = NSLocalizedString(
//        "postSettings.tags.label",
//        value: "Tags",
//        comment: "Label for the tags field. Should be the same as WP core."
//    )
//
//    static let addTag = NSLocalizedString(
//        "postSettings.tags.addTagButton",
//        value: "Add Tag",
//        comment: "Label for the add tag button field. Should be the same as WP core."
//    )
//}
