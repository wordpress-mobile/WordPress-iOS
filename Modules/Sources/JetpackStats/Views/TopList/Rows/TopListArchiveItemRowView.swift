import SwiftUI

struct TopListArchiveItemRowView: View {
    let item: TopListData.ArchiveItem

    var body: some View {
        Text(item.value)
            .font(.callout)
            .foregroundColor(.primary)
            .lineLimit(1)
            .lineSpacing(-2)
    }
}
