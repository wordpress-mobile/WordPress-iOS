import SwiftUI
import WordPressKit
import WordPressUI
import WordPressShared
import Gridicons
import UIKit

struct ActivityLogDetailsView: View {
    let activity: Activity
    let blog: Blog

    @State private var isLoadingRewindStatus = false

    private let formattableActivity: FormattableActivity

    init(activity: Activity, blog: Blog) {
        self.activity = activity
        self.blog = blog
        self.formattableActivity = FormattableActivity(with: activity)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ActivityHeaderView(activity: activity, blog: blog, formattableActivity: formattableActivity)
                if activity.isRewindable {
                    restoreSiteCard
                }
                if let actor = activity.actor {
                    makeActorCard(for: actor)
                }
            }
            .padding()
        }
        .navigationTitle(Strings.eventTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            trackDetailViewed()
        }
    }

    private func makeActorCard(for actor: ActivityActor) -> some View {
        CardView(Strings.user) {
            HStack(spacing: 12) {
                // Actor avatar
                ActivityActorAvatarView(actor: actor, diameter: 40)

                // Actor info
                VStack(alignment: .leading, spacing: 2) {
                    Text(actor.displayName.isEmpty ? Activity.Strings.unknownUser : actor.displayName)
                        .font(.headline)

                    Text(actor.role.isEmpty ? actor.type.localizedCapitalized : actor.role.localizedCapitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private var restoreSiteCard: some View {
        CardView(Strings.restoreSite) {
            // Checkpoint date info row
            InfoRow(Strings.checkpointDate) {
                Text(activity.published.formatted(date: .abbreviated, time: .standard))
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    handleRestoreTapped()
                }) {
                    ZStack {
                        Label(Strings.restore, systemImage: "arrow.counterclockwise")
                            .fontWeight(.medium)
                            .opacity(isLoadingRewindStatus ? 0 : 1)

                        if isLoadingRewindStatus {
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoadingRewindStatus)

                Button(action: {
                    trackBackupTapped()
                    ActivityLogDetailsCoordinator.presentBackup(activity: activity, blog: blog)
                }) {
                    Label(Strings.download, systemImage: "arrow.down.circle")
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
        }
    }
}

// MARK: - Header View

private struct ActivityHeaderView: View {
    let activity: Activity
    let blog: Blog
    let formattableActivity: FormattableActivity

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
                    ActivityFormattableContentView(
                        formattableActivity: formattableActivity,
                        blog: blog
                    )
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("—")
                        .font(.body)
                        .foregroundColor(.secondary)
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

    static let restoreSite = NSLocalizedString(
        "activityDetail.section.restoreSite",
        value: "Restore Site",
        comment: "Section title for restore site actions"
    )

    static let checkpointDate = NSLocalizedString(
        "activityDetail.checkpointDate",
        value: "Checkpoint Date",
        comment: "Label for the backup checkpoint date"
    )

    static let restore = NSLocalizedString(
        "activityDetail.restore.button",
        value: "Restore",
        comment: "Button title for restoring a backup"
    )

    static let download = NSLocalizedString(
        "activityDetail.download.button",
        value: "Download",
        comment: "Button title for downloading a backup"
    )
}

// MARK: - Actions

private extension ActivityLogDetailsView {
    func handleRestoreTapped() {
        trackRestoreTapped()

        guard let siteRef = JetpackSiteRef(blog: blog) else {
            return
        }

        isLoadingRewindStatus = true

        let service = JetpackRestoreService(coreDataStack: ContextManager.shared)
        service.getRewindStatus(for: siteRef) { rewindStatus in
            DispatchQueue.main.async {
                self.isLoadingRewindStatus = false
                ActivityLogDetailsCoordinator.presentRestore(activity: self.activity, blog: self.blog, rewindStatus: rewindStatus)
            }
        } failure: { error in
            DispatchQueue.main.async {
                self.isLoadingRewindStatus = false
                DDLogError("Failed to fetch rewind status: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Analytics

private extension ActivityLogDetailsView {
    func trackDetailViewed() {
        WPAnalytics.track(.activityLogDetailViewed, withProperties: ["source": presentedFrom()])
    }

    func trackRestoreTapped() {
        WPAnalytics.track(.restoreOpened, properties: ["source": "activity_detail"])
    }

    func trackBackupTapped() {
        WPAnalytics.track(.backupDownloadOpened, properties: ["source": "activity_detail"])
    }

    func presentedFrom() -> String {
        // Since we're in SwiftUI, we'll default to "activity_log"
        // In the future, this could be passed as a parameter
        return "activity_log"
    }
}

// MARK: - Preview Helpers

extension Blog {
    static var mock: Blog {
        // For previews, we'll return a dummy blog object
        // In real previews, this should be provided by the parent view
        return Blog()
    }
}
