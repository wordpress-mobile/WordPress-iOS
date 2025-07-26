import SwiftUI

struct TopListLocationRowView: View {
    let item: TopListData.Location

    var body: some View {
        HStack(spacing: Constants.step2 / 2) {
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
