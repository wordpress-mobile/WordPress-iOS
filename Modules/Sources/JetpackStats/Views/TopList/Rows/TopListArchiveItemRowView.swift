import SwiftUI

struct TopListArchiveItemRowView: View {
    let item: TopListItem.ArchiveItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.value)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(item.href)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
