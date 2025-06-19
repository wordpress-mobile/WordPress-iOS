import SwiftUI
import WordPressKit

struct ActivityLogDetailsView: View {
    let activity: Activity
    let rewindStatus: RewindStatus?
    
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
                        rewindStatus: rewindStatus,
                        isRestoring: $isRestoring,
                        isDownloadingBackup: $isDownloadingBackup,
                        onRestore: handleRestore,
                        onDownloadBackup: handleDownloadBackup
                    )
                }
                
                if let rewindStatus = rewindStatus, rewindStatus.state == .awaitingCredentials {
                    WarningCard(
                        message: "Rewind is not available for multisite installations. Visit Jetpack.com for more information.",
                        actionTitle: "Learn More",
                        action: openSupportURL
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Restore Site", isPresented: $isShowingRestoreConfirmation, actions: {
            Button(role: .destructive) {
                performRestore()
            } label: {
                Text("Restore to this point")
            }
        }, message: {
            Text("This will restore your site to \(activity.published.formatted(date: .abbreviated, time: .shortened)). Any changes made after this point will be lost.")
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
    
    var iconName: String {
        // Map gridicon names to SF Symbols
        switch activity.gridicon {
        case "cloud": return "cloud.fill"
        case "checkmark": return "checkmark.circle.fill"
        case "history": return "clock.arrow.circlepath"
        case "user": return "person.circle.fill"
        case "lock": return "lock.fill"
        case "plugins": return "puzzlepiece.fill"
        case "themes": return "paintbrush.fill"
        case "posts": return "doc.text.fill"
        case "pages": return "doc.fill"
        case "trash": return "trash.fill"
        case "notice": return "exclamationmark.triangle.fill"
        default: return "circle.fill"
        }
    }
    
    var backgroundColor: Color {
        switch activity.status {
        case "success": return .green
        case "error": return .red
        case "warning": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.2))
            
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(backgroundColor)
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
                    icon: "puzzlepiece.fill",
                    title: "Plugins",
                    value: "\(stats.plugins)"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: "paintbrush.fill",
                    title: "Themes",
                    value: "\(stats.themes)"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: "photo.fill",
                    title: "Uploads",
                    value: "\(stats.uploads)"
                )
            }
            
            HStack {
                StatItem(
                    icon: "doc.text.fill",
                    title: "Posts",
                    value: "\(stats.posts)"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: "doc.fill",
                    title: "Pages",
                    value: "\(stats.pages)"
                )
                
                Spacer()
            }
        }
    }
}

private struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.footnote)
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
        ActivityCard("Activity Details") {
            VStack(alignment: .leading, spacing: 16) {
                InfoRow("Type", value: formatActivityType(activity.type))
                InfoRow("Name", value: formatActivityName(activity.name))
                InfoRow("Status", value: activity.status.capitalized)
                
                if !activity.summary.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summary")
                            .font(.subheadline.weight(.medium))
                        Text(activity.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !activity.text.isEmpty && activity.text != activity.summary {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Details")
                            .font(.subheadline.weight(.medium))
                        Text(activity.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let rewindID = activity.rewindID {
                    InfoRow("Backup ID", value: String(rewindID.prefix(8)) + "...")
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
    let rewindStatus: RewindStatus?
    @Binding var isRestoring: Bool
    @Binding var isDownloadingBackup: Bool
    let onRestore: () -> Void
    let onDownloadBackup: () -> Void
    
    var canRestore: Bool {
        rewindStatus?.state == .active
    }
    
    var body: some View {
        ActivityCard("Actions") {
            VStack(spacing: 12) {
                Button(action: onRestore) {
                    Label {
                        Text("Restore to this point")
                    } icon: {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canRestore || isRestoring)
                
                Button(action: onDownloadBackup) {
                    Label {
                        Text("Download backup")
                    } icon: {
                        if isDownloadingBackup {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isDownloadingBackup)
                
                if !canRestore {
                    Text("Restore is not available for this site")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        ActivityLogDetailsView(
            activity: mockBackupActivity,
            rewindStatus: mockActiveRewindStatus
        )
    }
}

#Preview("Plugin Update") {
    NavigationView {
        ActivityLogDetailsView(
            activity: mockPluginActivity,
            rewindStatus: mockInactiveRewindStatus
        )
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

private let mockActiveRewindStatus = RewindStatus(state: .active)

private let mockInactiveRewindStatus = RewindStatus(state: .inactive)

