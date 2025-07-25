import SwiftUI

struct TopListArchiveItemRowView: View {
    let item: TopListData.ArchiveItem
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack(alignment: .leading) {
                // Ensure stable height
                Text(item.value)
                    .lineLimit(1, reservesSpace: true)
                    .opacity(0)
                Text(item.value)
            }
            .font(.callout)
            .foregroundColor(.primary)
            .lineLimit(1)
            .padding(.trailing, 4)
        }
    }
}
