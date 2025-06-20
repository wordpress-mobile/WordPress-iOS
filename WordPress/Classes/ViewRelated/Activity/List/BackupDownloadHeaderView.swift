import SwiftUI
import WordPressUI

struct BackupDownloadHeaderView: View {
    let backupStatus: JetpackBackup
    let onDownload: () -> Void
    let onDismiss: () -> Void

    private var formattedDate: String {
        let backupPoint = backupStatus.backupPoint
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy 'at' h:mm a")
        return formatter.string(from: backupPoint)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.successTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text(String(format: Strings.message, formattedDate))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Button(action: onDownload) {
                        Label(Strings.download, systemImage: "arrow.down.circle")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private enum Strings {
    static let successTitle = NSLocalizedString(
        "backup.download.header.title",
        value: "Backup Ready",
        comment: "Title shown when a backup is ready to download"
    )

    static let message = NSLocalizedString(
        "backup.download.header.message",
        value: "We successfully created a backup of your site as of %@",
        comment: "Message displayed when a backup has finished. %@ is the date and time."
    )

    static let download = NSLocalizedString(
        "backup.download.header.download",
        value: "Download",
        comment: "Download button title"
    )
}
