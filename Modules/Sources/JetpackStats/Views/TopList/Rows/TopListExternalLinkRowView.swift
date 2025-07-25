import SwiftUI

struct TopListExternalLinkRowView: View {
    let item: TopListData.ExternalLink

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.right.square")
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title ?? item.url)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
