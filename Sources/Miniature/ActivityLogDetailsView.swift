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
                
                if let stats = makeActivityStats() {
                    ActivityStatsCard(stats: stats)
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
    
    private func makeActivityStats() -> ActivityStats? {
        // Extract stats from activity content if available
        guard activity.name == "rewind__backup_complete_full" else { return nil }
        
        // Parse the text to extract backup stats
        let components = activity.text.components(separatedBy: ", ")
        var stats = ActivityStats()
        
        for component in components {
            if component.contains("plugin") {
                stats.plugins = Int(component.components(separatedBy: " ").first ?? "0") ?? 0
            } else if component.contains("theme") {
                stats.themes = Int(component.components(separatedBy: " ").first ?? "0") ?? 0
            } else if component.contains("upload") {
                stats.uploads = Int(component.components(separatedBy: " ").first ?? "0") ?? 0
            } else if component.contains("post") {
                stats.posts = Int(component.components(separatedBy: " ").first ?? "0") ?? 0
            } else if component.contains("page") {
                stats.pages = Int(component.components(separatedBy: " ").first ?? "0") ?? 0
            }
        }
        
        return stats
    }
}

// MARK: - Header View

private struct ActivityHeaderView: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            ActivityIconView(activity: activity)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.actor?.displayName ?? "WordPress")
                    .font(.headline)
                
                if let role = activity.actor?.role {
                    Text(role.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.published.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(activity.published.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Icon View

private struct ActivityIconView: View {
    let activity: Activity
    
    var body: some View {
        if let icon = activity.icon {
            ZStack {
                Circle()
                    .fill(Color(activity.statusColor))
                
                Image(uiImage: icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .padding(12)
            }
        } else if let avatarURL = activity.actor?.avatarURL, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
            // User avatar
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(uiImage: .gridicon(.user, size: CGSize(width: 24, height: 24)))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .clipShape(Circle())
            .background(Circle().fill(Color(.systemGray5)))
        } else {
            // Fallback
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                
                Image(uiImage: .gridicon(.pages, size: CGSize(width: 24, height: 24)))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
}

// MARK: - Stats Card

private struct ActivityStats {
    var plugins: Int = 0
    var themes: Int = 0
    var uploads: Int = 0
    var posts: Int = 0
    var pages: Int = 0
}

private struct ActivityStatsCard: View {
    let stats: ActivityStats
    
    var body: some View {
        ActivityCard {
            HStack {
                StatItem(
                    icon: .gridicon(.plugins, size: CGSize(width: 20, height: 20)),
                    title: Strings.plugins,
                    value: "\(stats.plugins)"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: .gridicon(.themes, size: CGSize(width: 20, height: 20)),
                    title: Strings.themes,
                    value: "\(stats.themes)"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: .gridicon(.image, size: CGSize(width: 20, height: 20)),
                    title: Strings.uploads,
                    value: "\(stats.uploads)"
                )
            }
            
            HStack {
                StatItem(
                    icon: .gridicon(.posts, size: CGSize(width: 20, height: 20)),
                    title: Strings.posts,
                    value: "\(stats.posts)"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: .gridicon(.pages, size: CGSize(width: 20, height: 20)),
                    title: Strings.pages,
                    value: "\(stats.pages)"
                )
                
                Spacer()
            }
        }
    }
}

private struct StatItem: View {
    let icon: UIImage
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(uiImage: icon)
                .renderingMode(.template)
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Details Card

private struct ActivityDetailsCard: View {
    let activity: Activity
    
    var body: some View {
        ActivityCard(Strings.activityDetails) {
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(Strings.type, value: formatActivityType(activity.type))
                InfoRow(Strings.name, value: formatActivityName(activity.name))
                InfoRow(Strings.status, value: activity.status.localizedCapitalized)
                
                if !activity.summary.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.summary)
                            .font(.subheadline.weight(.medium))
                        Text(activity.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !activity.text.isEmpty && activity.text != activity.summary {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.details)
                            .font(.subheadline.weight(.medium))
                        Text(activity.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let rewindID = activity.rewindID {
                    InfoRow(Strings.backupID, value: String(rewindID.prefix(8)) + "...")
                        .font(.caption)
                }
            }
        }
    }
    
    private func formatActivityType(_ type: String) -> String {
        type.replacingOccurrences(of: "_", with: " ").capitalized
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
        ActivityLogDetailsView(activity: mockBackupActivity)
    }
}

#Preview("Plugin Update") {
    NavigationView {
        ActivityLogDetailsView(activity: mockPluginActivity)
    }
}

// MARK: - Mock Data

private let mockBackupActivity: Activity = {
    let json = """
    {
        "activity_id": "123456",
        "summary": "Backup and scan complete",
        "content": {
            "text": "9 plugins, 2 themes, 45 uploads, 27 posts, 1 page"
        },
        "name": "rewind__backup_complete_full",
        "type": "backup",
        "gridicon": "cloud",
        "status": "success",
        "is_rewindable": true,
        "rewind_id": "abc123def456",
        "published": "2025-06-18T17:35:00+00:00",
        "actor": {
            "name": "Jetpack",
            "type": "Application",
            "wp_com_user_id": "",
            "icon": {
                "url": ""
            },
            "role": ""
        }
    }
    """
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let date = Date.dateWithISO8601WithMillisecondsString(dateString) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
    }
    
    return try! decoder.decode(Activity.self, from: json.data(using: .utf8)!)
}()

private let mockPluginActivity: Activity = {
    let json = """
    {
        "activity_id": "789012",
        "summary": "Plugin updated",
        "content": {
            "text": "Updated Akismet Anti-spam from version 5.2 to 5.3"
        },
        "name": "plugin__updated",
        "type": "plugin",
        "gridicon": "plugins",
        "status": "success",
        "is_rewindable": false,
        "published": "2025-06-18T16:35:00+00:00",
        "actor": {
            "name": "John Doe",
            "type": "Person",
            "wp_com_user_id": "12345",
            "icon": {
                "url": "https://gravatar.com/avatar/12345"
            },
            "role": "administrator"
        }
    }
    """
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let date = Date.dateWithISO8601WithMillisecondsString(dateString) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
    }
    
    return try! decoder.decode(Activity.self, from: json.data(using: .utf8)!)
}()

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
    
    // Stats
    static let plugins = NSLocalizedString(
        "activityDetail.stats.plugins",
        value: "Plugins",
        comment: "Label for number of plugins in backup"
    )
    
    static let themes = NSLocalizedString(
        "activityDetail.stats.themes",
        value: "Themes",
        comment: "Label for number of themes in backup"
    )
    
    static let uploads = NSLocalizedString(
        "activityDetail.stats.uploads",
        value: "Uploads",
        comment: "Label for number of uploads in backup"
    )
    
    static let posts = NSLocalizedString(
        "activityDetail.stats.posts",
        value: "Posts",
        comment: "Label for number of posts in backup"
    )
    
    static let pages = NSLocalizedString(
        "activityDetail.stats.pages",
        value: "Pages",
        comment: "Label for number of pages in backup"
    )
}

