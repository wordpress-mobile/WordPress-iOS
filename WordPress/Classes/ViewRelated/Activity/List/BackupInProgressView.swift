import SwiftUI
import WordPressUI

struct BackupInProgressView: View {
    let progress: Int

    private var progressFloat: Float {
        max(Float(progress) / 100, 0.05) // Show at least 5% for UX
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(Strings.message)
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

private enum Strings {
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
