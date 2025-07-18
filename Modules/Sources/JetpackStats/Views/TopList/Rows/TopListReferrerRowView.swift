import SwiftUI

struct TopListReferrerRowView: View {
    let item: TopListData.Referrer
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            if showDetails, let domain = item.domain {
                Text(domain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
