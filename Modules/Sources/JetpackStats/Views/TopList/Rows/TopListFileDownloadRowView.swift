import SwiftUI

struct TopListFileDownloadRowView: View {
    let item: TopListData.FileDownload
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.fileName)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            if showDetails, let filePath = item.filePath {
                Text(verbatim: filePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
