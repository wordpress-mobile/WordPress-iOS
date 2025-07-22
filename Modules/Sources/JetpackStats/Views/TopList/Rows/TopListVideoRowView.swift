import SwiftUI

struct TopListVideoRowView: View {
    let item: TopListData.Video
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.title)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            if showDetails {
                Text(Strings.Videos.postId(item.postId))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
