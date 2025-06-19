import SwiftUI
import WordPressKit
import WordPressUI
import Gridicons

struct ActivityLogDetailsView: View {
    let activity: Activity
    let blog: Blog

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    ActivityHeaderView(activity: activity)
                    if let actor = activity.actor {
                        ActorCard(actor: actor)
                    }
                }
                .padding()
            }
            
            if shouldShowBackupActions {
                actionButtons
            }
        }
        .navigationTitle(Strings.eventTitle)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            ActivityLogDetailsCoordinator(
                activity: activity,
                blog: blog
            )
        )
    }
    
    private var shouldShowBackupActions: Bool {
        // Show buttons for rewindable activities that are backup-related
        guard activity.isRewindable else { return false }
        
        // Check if this is a backup activity based on the activity name
        let backupActivityNames = [
            "rewind__backup_complete_full",
            "rewind__backup_complete",
            "rewind__backup_error"
        ]
        
        return backupActivityNames.contains(activity.name)
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                // Restore Backup - Primary Button
                Button(action: {
                    ActivityLogDetailsCoordinator.shared?.presentRestore()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text(Strings.restoreBackup)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Download Backup - Secondary Button
                Button(action: {
                    ActivityLogDetailsCoordinator.shared?.presentBackup()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 16, weight: .regular))
                        Text(Strings.downloadBackup)
                            .font(.system(size: 16, weight: .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.clear)
                    .foregroundColor(.accentColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
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

                // Activity details
                if !activity.text.isEmpty {
                    if let formattedContent = activity.formattedContent {
                        Text(formattedContent)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .tint(Color.accentColor)
                    } else {
                        Text(activity.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }

                // Date and time
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.tertiary)
                    Text(activity.published.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .padding(.top, 8)
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
                ActivityActorAvatarView(actor: actor, diameter: 40)

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
            if let title {
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

// MARK: - Preview

#Preview("Backup Activity") {
    NavigationView {
        ActivityLogDetailsView(
            activity: ActivityLogDetailsView.Mocks.mockBackupActivity,
            blog: Blog.mock
        )
    }
}

#Preview("Plugin Update") {
    NavigationView {
        ActivityLogDetailsView(
            activity: ActivityLogDetailsView.Mocks.mockPluginActivity,
            blog: Blog.mock
        )
    }
}

#Preview("Login Succeeded") {
    NavigationView {
        ActivityLogDetailsView(
            activity: ActivityLogDetailsView.Mocks.mockLoginActivity,
            blog: Blog.mock
        )
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let eventTitle = NSLocalizedString(
        "activityDetail.title",
        value: "Event",
        comment: "Title for the activity detail view"
    )

    static let user = NSLocalizedString(
        "activityDetail.section.user",
        value: "User",
        comment: "Section title for user information"
    )
    
    static let restoreBackup = NSLocalizedString(
        "activityDetail.restoreBackup.button",
        value: "Restore Backup",
        comment: "Button title for restoring a backup"
    )
    
    static let downloadBackup = NSLocalizedString(
        "activityDetail.downloadBackup.button",
        value: "Download Backup",
        comment: "Button title for downloading a backup"
    )
}

// MARK: - Preview Helpers

#if DEBUG
extension Blog {
    static var mock: Blog {
        // For previews, we'll return a dummy blog object
        // In real previews, this should be provided by the parent view
        return Blog()
    }
}
#endif
