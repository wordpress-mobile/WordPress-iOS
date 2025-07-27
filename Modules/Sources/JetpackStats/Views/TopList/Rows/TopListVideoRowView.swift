import SwiftUI

struct TopListVideoRowView: View {
    let item: TopListItem.Video

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(Image(systemName: "play.circle")).font(.footnote) + Text(" ") + Text(item.title))
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            if let videoURL = item.videoURL?.absoluteString, !videoURL.isEmpty {
                Text(videoURL)
                    .font(.footnote)
                    .truncationMode(.middle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
