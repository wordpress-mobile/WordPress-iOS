import SwiftUI

struct TopListUTMMetricRowView: View {
    let item: TopListItem.UTMMetric

    var body: some View {
        HStack(spacing: Constants.step0_5) {
            VStack(alignment: .leading, spacing: 1) {
                Text(item.label)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let posts = item.posts, !posts.isEmpty {
                    Text(Strings.UTMMetricDetails.postCount(posts.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
