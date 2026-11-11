import SwiftUI
import WordPressShared

struct TopListPostRowView: View {
    let item: TopListItem.Post

    @Environment(\.postThumbnailStore) private var thumbnailStore

    var body: some View {
        HStack(spacing: Constants.step0_5) {
            if let thumbnailStore {
                StatsPostThumbnailView(item: item, store: thumbnailStore)
            }

            Text(item.title)
                .font(.callout)
                .foregroundColor(.primary)
                .lineSpacing(-2)
                .lineLimit(2)
        }
    }
}
