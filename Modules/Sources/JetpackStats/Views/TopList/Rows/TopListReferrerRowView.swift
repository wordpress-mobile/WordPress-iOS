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

                if let domain = item.domain {
                    if let url = URL(string: "https://\(domain)") {
                        Link(domain, destination: url)
                            .font(.caption)
                            .lineLimit(1)
                    } else {
                        Text(domain)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
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
