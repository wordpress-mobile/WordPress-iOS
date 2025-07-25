import SwiftUI

struct TopListLocationRowView: View {
    let item: TopListData.Location

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if let flag = item.flag {
                    Text(flag)
                        .font(.callout)
                }
                Text(item.country)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            if let countryCode = item.countryCode {
                Text(countryCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
