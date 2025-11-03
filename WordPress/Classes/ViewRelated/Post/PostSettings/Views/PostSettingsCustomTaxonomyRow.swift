import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

struct PostSettingsCustomTaxonomyRow: View {
    let taxonomy: SiteTaxonomy
    let terms: [String]

    var body: some View {
        HStack {
            PostSettingsIconView("wpdl-tag")
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(taxonomy.localizedName)
                    .font(.body)
                    .foregroundColor(.primary)
                if terms.isEmpty {
                    Text(String.localizedStringWithFormat(Strings.addNewFormat, taxonomy.localizedName))
                        .font(.subheadline)
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    PostSettingsTruncatedArrayTextView(values: terms)
                }
            }

            Spacer()
        }
    }
}

private enum Strings {
    static let addNewFormat = NSLocalizedString(
        "siteTaxonomy.addNew.format",
        value: "Add %1$@",
        comment: "Format string for adding a new taxonomy term. %1$@ is the taxonomy name."
    )
}
