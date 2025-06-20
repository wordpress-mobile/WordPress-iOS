import SwiftUI
import WordPressUI
import WordPressKit

struct DownloadableBackupSection: View {
    @ObservedObject var backupTracker: DownloadableBackupTracker

    var body: some View {
        if let backupStatus = backupTracker.backupStatus {
            Group {
                if backupTracker.isBackupInProgress,
                   let progress = backupStatus.progress {
                    BackupInProgressView(progress: progress)
                } else if let url = backupTracker.downloadURL {
                    BackupDownloadHeaderView(
                        backupStatus: backupStatus,
                        onDownload: {
                            WPAnalytics.track(.backupFileDownloadTapped)
                            UIApplication.shared.open(url)
                        },
                        onDismiss: {
                            withAnimation {
                                backupTracker.dismissBackupNotice()
                            }
                        }
                    )
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Private Views

private struct BackupInProgressView: View {
    let progress: Int

    private var progressFloat: Float {
        max(Float(progress) / 100, 0.05) // Show at least 5% for UX
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.InProgress.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(Strings.InProgress.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progressFloat)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct BackupDownloadHeaderView: View {
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
                        Text(Strings.Download.successTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text(String(format: Strings.Download.message, formattedDate))
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
                        Text(Strings.Download.download)
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

// MARK: - Strings

private enum Strings {
    enum InProgress {
        static let title = NSLocalizedString(
            "backup.inProgress.title",
            value: "Backing up site",
            comment: "Title shown when a backup is in progress"
        )

        static let message = NSLocalizedString(
            "backup.inProgress.message",
            value: "Creating downloadable backup",
            comment: "Message shown when a backup is in progress"
        )
    }

    enum Download {
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
}
