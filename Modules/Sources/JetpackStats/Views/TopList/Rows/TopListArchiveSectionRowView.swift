import SwiftUI

struct TopListArchiveSectionRowView: View {
    let item: TopListItem.ArchiveSection

    var body: some View {
        HStack(spacing: Constants.step0_5) {
            Image(systemName: "folder")
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(Strings.ArchiveSections.itemCount(item.items.count))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}
