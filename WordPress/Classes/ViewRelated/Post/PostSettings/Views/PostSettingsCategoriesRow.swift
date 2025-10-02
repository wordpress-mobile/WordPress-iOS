import SwiftUI
import WordPressUI
import WordPressData

struct PostSettingsCategoriesRow: View {
    let categories: [String]

    var body: some View {
        HStack {
            PostSettingsIconView("wpdl-category")
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.categoriesLabel)
                    .font(.body)
                    .foregroundColor(.primary)

                if categories.isEmpty {
                    Text(Strings.addCategory)
                        .font(.subheadline)
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    PostSettingsTruncatedArrayTextView(values: categories)
                }
            }

            Spacer()
        }
    }
}

private enum Strings {
    static let categoriesLabel = NSLocalizedString(
        "postSettings.categories.label",
        value: "Categories",
        comment: "Label for the category field. Should be the same as WP core."
    )

    static let addCategory = NSLocalizedString(
        "postSettings.categories.addCategoryButton",
        value: "Add Category",
        comment: "Label for the add category button field. Should be the same as WP core."
    )
}
