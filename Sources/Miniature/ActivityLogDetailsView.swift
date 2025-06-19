import SwiftUI
import WordPressKit
import WordPressUI
import Gridicons

struct ActivityLogDetailsView: View {
    let activity: Activity
    
    @State private var isShowingRestoreConfirmation = false
    @State private var isRestoring = false
    @State private var isDownloadingBackup = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ActivityHeaderView(activity: activity)
                if let actor = activity.actor {
                    ActorCard(actor: actor)
                }
                ActivityDetailsCard(activity: activity)

                if activity.isRewindable {
                    ActivityActionsCard(
                        activity: activity,
                        isRestoring: $isRestoring,
                        isDownloadingBackup: $isDownloadingBackup,
                        onRestore: handleRestore,
                        onDownloadBackup: handleDownloadBackup
                    )
                }
            }
            .padding()
        }
        .navigationTitle(Strings.eventTitle)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(Strings.restoreConfirmationTitle, isPresented: $isShowingRestoreConfirmation, actions: {
            Button(role: .destructive) {
                performRestore()
            } label: {
                Text(Strings.restoreToThisPoint)
            }
        }, message: {
            Text(String(format: Strings.restoreConfirmationMessage, activity.published.formatted(date: .abbreviated, time: .shortened)))
        })
    }
    
    // MARK: - Actions
    
    private func handleRestore() {
        isShowingRestoreConfirmation = true
    }
    
    private func performRestore() {
        isRestoring = true
        // In a real implementation, this would call the restore API
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRestoring = false
        }
    }
    
    private func handleDownloadBackup() {
        isDownloadingBackup = true
        // In a real implementation, this would trigger the backup download
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isDownloadingBackup = false
        }
    }
    
    private func openSupportURL() {
        if let url = URL(string: "https://jetpack.com/support/backup/") {
            UIApplication.shared.open(url)
        }
    }
    
}

// MARK: - Header View

private struct ActivityHeaderView: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Activity icon with colored background
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(activity.statusColor).opacity(0.15))
                    .frame(width: 60, height: 60)

                if let icon = activity.icon {
                    Image(uiImage: icon)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(activity.statusColor))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                // Activity title/summary
                Text(activity.summary.localizedCapitalized)
                    .font(.title3.weight(.medium))
                    .lineLimit(2)

                // Activity details if different from summary
                if !activity.text.isEmpty && activity.text != activity.summary {
                    Text(activity.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                // Date and time
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.tertiary)
                    Text(activity.published.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Actor Card

private struct ActorCard: View {
    let actor: ActivityActor
    
    var body: some View {
        ActivityCard(Strings.user) {
            HStack(spacing: 12) {
                // Actor avatar
                ActorAvatarView(actor: actor)
                    .frame(width: 40, height: 40)
                
                // Actor info
                VStack(alignment: .leading, spacing: 2) {
                    Text(actor.displayName)
                        .font(.headline)
                    
                    Text(actor.role.isEmpty ? actor.type.localizedCapitalized : actor.role.localizedCapitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Actor Avatar View

private struct ActorAvatarView: View {
    let actor: ActivityActor
    
    var body: some View {
        if let url = URL(string: actor.avatarURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholder
            }
            .clipShape(Circle())
        } else if actor.displayName.lowercased() == "jetpack" {
            ZStack {
                Circle()
                    .fill(Color(.systemGreen))
                Image(uiImage: .gridicon(.plugins, size: CGSize(width: 18, height: 18)))
                    .foregroundColor(.white)
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        Circle()
            .fill(Color(.secondarySystemFill))
            .overlay(
                Text(actor.displayName.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            )
    }
}

// MARK: - Details Card

private struct ActivityDetailsCard: View {
    let activity: Activity
    
    var body: some View {
        ActivityCard(Strings.activityDetails) {
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(Strings.status, value: activity.status.localizedCapitalized)
                
                InfoRow(Strings.name, value: formatActivityName(activity.name))
                
                if let rewindID = activity.rewindID {
                    InfoRow(Strings.backupID, value: String(rewindID.prefix(8)) + "...")
                        .font(.caption)
                }
            }
        }
    }
    
    private func formatActivityName(_ name: String) -> String {
        name
            .replacingOccurrences(of: "__", with: " - ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Actions Card

private struct ActivityActionsCard: View {
    let activity: Activity
    @Binding var isRestoring: Bool
    @Binding var isDownloadingBackup: Bool
    let onRestore: () -> Void
    let onDownloadBackup: () -> Void
    
    var body: some View {
        ActivityCard(Strings.actions) {
            VStack(spacing: 12) {
                Button(action: onRestore) {
                    Label {
                        Text(Strings.restore)
                    } icon: {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(uiImage: .gridicon(.history, size: CGSize(width: 20, height: 20)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRestoring)
                
                Button(action: onDownloadBackup) {
                    Label {
                        Text(Strings.downloadBackup)
                    } icon: {
                        if isDownloadingBackup {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(uiImage: .gridicon(.cloudDownload, size: CGSize(width: 20, height: 20)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isDownloadingBackup)
            }
        }
    }
}

// MARK: - Warning Card

private struct WarningCard: View {
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        ActivityCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Button(actionTitle, action: action)
                    .font(.subheadline)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Shared Components

private struct ActivityCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    
    init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    
    init(_ title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview

#Preview("Backup Activity") {
    NavigationView {
        ActivityLogDetailsView(activity: ActivityLogDetailsView.Mocks.mockBackupActivity)
    }
}

#Preview("Plugin Update") {
    NavigationView {
        ActivityLogDetailsView(activity: ActivityLogDetailsView.Mocks.mockPluginActivity)
    }
}

#Preview("Login Succeeded") {
    NavigationView {
        ActivityLogDetailsView(activity: ActivityLogDetailsView.Mocks.mockLoginActivity)
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let eventTitle = NSLocalizedString(
        "activityDetail.title",
        value: "Event",
        comment: "Title for the activity detail view"
    )
    
    static let restore = NSLocalizedString(
        "activityDetail.restore",
        value: "Restore",
        comment: "Title for button allowing user to restore their Jetpack site"
    )
    
    static let downloadBackup = NSLocalizedString(
        "activityDetail.downloadBackup",
        value: "Download backup",
        comment: "Title for button allowing user to backup their Jetpack site"
    )
    
    static let restoreToThisPoint = NSLocalizedString(
        "activityDetail.restoreToThisPoint",
        value: "Restore to this point",
        comment: "Confirmation button text for restoring site"
    )
    
    static let restoreConfirmationTitle = NSLocalizedString(
        "activityDetail.restoreConfirmationTitle",
        value: "Restore Site",
        comment: "Title for restore confirmation dialog"
    )
    
    static let restoreConfirmationMessage = NSLocalizedString(
        "activityDetail.restoreConfirmationMessage",
        value: "This will restore your site to %@. Any changes made after this point will be lost.",
        comment: "Message for restore confirmation dialog. %@ is the date/time."
    )
    
    static let restoreNotAvailable = NSLocalizedString(
        "activityDetail.restoreNotAvailable",
        value: "Restore is not available for this site",
        comment: "Message shown when restore is not available"
    )
    
    static let multisiteWarning = NSLocalizedString(
        "activityDetail.multisiteWarning",
        value: "Rewind is not available for multisite installations. Visit Jetpack.com for more information.",
        comment: "Warning message for multisite installations"
    )
    
    static let learnMore = NSLocalizedString(
        "activityDetail.learnMore",
        value: "Learn More",
        comment: "Button text to learn more about limitations"
    )
    
    static let activityDetails = NSLocalizedString(
        "activityDetail.section.details",
        value: "Activity Details",
        comment: "Section title for activity details"
    )
    
    static let actions = NSLocalizedString(
        "activityDetail.section.actions",
        value: "Actions",
        comment: "Section title for available actions"
    )
    
    static let type = NSLocalizedString(
        "activityDetail.field.type",
        value: "Type",
        comment: "Activity type field label"
    )
    
    static let name = NSLocalizedString(
        "activityDetail.field.name",
        value: "Name",
        comment: "Activity name field label"
    )
    
    static let status = NSLocalizedString(
        "activityDetail.field.status",
        value: "Status",
        comment: "Activity status field label"
    )
    
    static let summary = NSLocalizedString(
        "activityDetail.field.summary",
        value: "Summary",
        comment: "Activity summary field label"
    )
    
    static let details = NSLocalizedString(
        "activityDetail.field.details",
        value: "Details",
        comment: "Activity details field label"
    )
    
    static let backupID = NSLocalizedString(
        "activityDetail.field.backupID",
        value: "Backup ID",
        comment: "Backup ID field label"
    )
    
    static let user = NSLocalizedString(
        "activityDetail.section.user",
        value: "User",
        comment: "Section title for user information"
    )
}

