import SwiftUI
import WordPressShared

struct TopListPostRowView: View {
    let item: TopListData.Post
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack(alignment: .leading) {
                // Ensure stable height
                Text(item.title)
                    .lineLimit(2, reservesSpace: true)
                    .opacity(0)
                Text(item.title)
            }
            .font(.callout)
            .foregroundColor(.primary)
            .lineLimit(2)
        }
    }
}
