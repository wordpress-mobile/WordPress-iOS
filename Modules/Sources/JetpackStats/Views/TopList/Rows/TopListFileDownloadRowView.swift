import SwiftUI

struct TopListFileDownloadRowView: View {
    let item: TopListItem.FileDownload

    var body: some View {
        Text(item.fileName)
            .font(.callout)
            .foregroundColor(.primary)
            .lineLimit(2)
            .lineSpacing(-2)
    }
}
