import SwiftUI

struct TopListExternalLinkRowView: View {
    let item: TopListItem.ExternalLink

    var body: some View {
        HStack(spacing: Constants.step0_5) {
            StatsFaviconView(iconURL: item.iconURL)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title ?? item.url)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if !item.children.isEmpty {
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
}
