import SwiftUI

struct TopListExternalLinkRowView: View {
    let item: TopListData.ExternalLink

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title ?? item.url)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(item.url)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
