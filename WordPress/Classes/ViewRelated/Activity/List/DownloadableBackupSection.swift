import SwiftUI
import WordPressUI
import WordPressKit

/// Represents the current status of a downloadable backup.
enum DownloadableBackupStatus {
    /// Backup creation is in progress or processing
    case inProgress(backup: JetpackBackup, progress: Int)

    /// Backup is ready for download
    case readyToDownload(backup: JetpackBackup, url: URL, validUntil: Date)

    init?(backup: JetpackBackup?) {
        guard let backup else {
            return nil
        }

        // Determine the status based on the backup properties
        if let urlString = backup.url,
                  let url = URL(string: urlString),
                  let validUntil = backup.validUntil,
                  Date() < validUntil {
            // Download is ready and valid
            self = .readyToDownload(backup: backup, url: url, validUntil: validUntil)
        } else if let progress = backup.progress, progress > 0 {
            // Backup is being created or processing
            self = .inProgress(backup: backup, progress: progress)
        } else {
            // Backup exists but in an unknown state
            return nil
        }
    }
}

struct DownloadableBackupSection: View {
    @ObservedObject var backupTracker: DownloadableBackupTracker

    var body: some View {
        if let status = DownloadableBackupStatus(backup: backupTracker.backup) {
            CardView {
                switch status {
                case .inProgress(let backup, let progress):
                    BackupInProgressView(backup: backup, progress: progress)

                case .readyToDownload(let backup, let url, let validUntil):
                    BackupDownloadHeaderView(
                        backup: backup,
                        url: url,
                        validUntil: validUntil,
                        backupTracker: backupTracker
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Private Views

private struct BackupInProgressView: View {
    let backup: JetpackBackup
    let progress: Int

    private var progressFloat: Float {
        max(Float(progress) / 100, 0.05) // Show at least 5% for UX
    }

    var body: some View {
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

            HStack {
                ProgressView(value: progressFloat)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)

                Text("\(progress)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

private struct BackupDownloadHeaderView: View {
    let backup: JetpackBackup
    let url: URL
    let validUntil: Date
    let backupTracker: DownloadableBackupTracker

    private var formattedBackupDate: String {
        backup.backupPoint.formatted(date: .abbreviated, time: .shortened)
    }

    private var formattedExpiryDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: validUntil, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            downloadButton
        }
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Download.successTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(String(format: Strings.Download.message, formattedBackupDate))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(String(format: Strings.Download.expiresIn, formattedExpiryDate))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button(action: {
                withAnimation {
                    backupTracker.dismissBackupNotice()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var downloadButton: some View {
        HStack(spacing: 12) {
            Button(action: {
                WPAnalytics.track(.backupFileDownloadTapped)
                UIApplication.shared.open(url)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                    Text(Strings.Download.download)
                }
                .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}

// MARK: - Strings

private enum Strings {
    enum InProgress {
        static let title = NSLocalizedString(
            "backup.inProgress.title",
            value: "Creating downloadable backup",
            comment: "Title shown when a downloadable backup is being created"
        )

        static let message = NSLocalizedString(
            "backup.inProgress.message",
            value: "Preparing your site backup for download",
            comment: "Message shown when a downloadable backup is in progress"
        )
    }

    enum Download {
        static let successTitle = NSLocalizedString(
            "backup.download.header.title",
            value: "Backup ready to download",
            comment: "Title shown when a backup is ready to download"
        )

        static let message = NSLocalizedString(
            "backup.download.header.message",
            value: "Your backup from %@ is ready",
            comment: "Message displayed when a backup has finished. %@ is the date and time."
        )

        static let expiresIn = NSLocalizedString(
            "backup.download.header.expiresIn",
            value: "Expires %@",
            comment: "Shows when the download link will expire. %@ is the relative time (e.g., 'in 2 hours')"
        )

        static let download = NSLocalizedString(
            "backup.download.header.download",
            value: "Download",
            comment: "Download button title"
        )
    }

}
