import SwiftUI
import WordPressUI

struct TopListReferrerRowView: View {
    let item: TopListItem.Referrer

    var body: some View {
        HStack(spacing: Constants.step0_5) {
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

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 0) {
                    if let domain = item.domain {
                        Text(verbatim: domain)
                            .font(.caption)
                    }
                    if !item.children.isEmpty {
                        let prefix = item.domain == nil ? "" : ","
                        Text(verbatim: "\(prefix) +\(item.children.count)")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "link")
    }
}
