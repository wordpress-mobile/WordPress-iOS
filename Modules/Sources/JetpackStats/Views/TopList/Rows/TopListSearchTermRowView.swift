import SwiftUI

struct TopListSearchTermRowView: View {
    let item: TopListItem.SearchTerm

    var body: some View {
        Text(item.term)
            .font(.callout)
            .foregroundColor(.primary)
            .lineLimit(2)
            .lineSpacing(-2)
    }
}
