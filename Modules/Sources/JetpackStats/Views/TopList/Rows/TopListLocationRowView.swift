import SwiftUI

struct TopListLocationRowView: View {
    let item: TopListItem.Location

    var body: some View {
        HStack(spacing: Constants.step0_5) {
            if let flag = item.flag {
                Text(flag)
                    .font(.title2)
            } else {
                Image(systemName: "map")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Text(item.country)
                .font(.body)
                .foregroundColor(.primary)
        }
        .lineLimit(1)
    }
}
