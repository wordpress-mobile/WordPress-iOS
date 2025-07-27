import SwiftUI
import WordPressShared

struct TopListPostRowView: View {
    let item: TopListItem.Post

    var body: some View {
        Text(item.title)
            .font(.callout)
            .foregroundColor(.primary)
            .lineSpacing(-2)
            .lineLimit(2)
    }
}
