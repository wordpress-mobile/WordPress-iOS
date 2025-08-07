import SwiftUI

struct TopListExternalLinkRowView: View {
    let item: TopListItem.ExternalLink

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title ?? item.url)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            if item.children.count > 0 {
                Text(Strings.ArchiveSections.itemCount(item.children.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text(item.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}
