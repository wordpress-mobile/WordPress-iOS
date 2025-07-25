import SwiftUI
import WordPressUI

struct TopListReferrerRowView: View {
    let item: TopListData.Referrer

    var body: some View {
        HStack(spacing: 8) {
            // Icon or placeholder
            if let iconURL = item.iconURL {
                CachedAsyncImage(url: iconURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    placeholderIcon
                }
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                placeholderIcon
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 0) {
                    if let domain = item.domain {
                        Text(verbatim: domain)
                            .font(.caption)
                    }
                    if !item.children.isEmpty {
                        let prefix = item.domain == nil ? "" : ","
                        Text(verbatim: "\(prefix) +\(item.children.count - 1)")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "link.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.secondary.opacity(0.5))
    }
}
