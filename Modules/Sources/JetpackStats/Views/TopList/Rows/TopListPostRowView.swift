import SwiftUI
import WordPressShared

struct TopListPostRowView: View {
    let item: TopListData.Post
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            if showDetails {
                if let author = item.author {
                    Text(verbatim: author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let date = item.date {
                    Text(verbatim: date.toMediumString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
