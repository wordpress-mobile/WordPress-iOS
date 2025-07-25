import SwiftUI

struct TopListSearchTermRowView: View {
    let item: TopListData.SearchTerm

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.term)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(Strings.SearchTerms.fromSearch)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}
