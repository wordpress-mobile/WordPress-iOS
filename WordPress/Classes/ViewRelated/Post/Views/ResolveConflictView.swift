import SwiftUI
import UIKit
import WordPressKit
import WordPressShared

struct ResolveConflictView: View {
    enum Source: String {
        case editor
        case postList = "post_list"
        case pageList = "page_list"
    }

    let post: AbstractPost
    let remoteRevision: RemotePost
    let repository: PostRepository
    let source: Source
    var dismiss: (() -> Void)?

    private var versions: [PostVersion] { [.local(post), .remote(remoteRevision)] }

    @State private var selectedVersion: PostVersion?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if let title = post.latest().titleForDisplay() {
                        Text("\"\(title)\"")
                            .font(.headline)
                            .lineLimit(2)
                    }
                    Text(Strings.description)
                }
                ForEach(versions) { version in
                    PostVersionView(version: version, selectedVersion: $selectedVersion)
                }
            }
        }
        .navigationTitle(Strings.Navigation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .interactiveDismissDisabled()
        .onAppear {
            track(.resolveConflictScreenShown)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(Strings.Navigation.cancel) {
                track(.resolveConflictCancelTapped)
                dismiss?()
            }.disabled(isSaving)
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if isSaving {
                ProgressView()
            } else {
                Button(Strings.Navigation.save) {
                    guard let selectedVersion else {
                        dismiss?()
                        return
                    }
                    track(.resolveConflictSaveTapped)
                    Task { @MainActor in
                        saveSelectedVersion(selectedVersion, post: post, remoteRevision: remoteRevision)
                    }
                }.disabled(selectedVersion == nil)
            }
        }
    }

    @MainActor
    private func saveSelectedVersion(_ version: PostVersion, post: AbstractPost, remoteRevision: RemotePost) {
        isSaving = true
        switch version {
        case .local:
            handleLocalVersionSelected(for: post)
        case .remote:
            handleRemoteVersionSelected(for: post, remoteRevision: remoteRevision)
        }
    }

    private func handleLocalVersionSelected(for post: AbstractPost) {
        Task { @MainActor in
            do {
                try await repository.save(post, overwrite: true)
                PostCoordinator.shared.didResolveConflict(for: post)
                dismiss?()
            } catch {
                DDLogError("Error resolving conflict picking local version: \(error)")
            }
            isSaving = false
        }
    }

    @MainActor
    private func handleRemoteVersionSelected(for post: AbstractPost, remoteRevision: RemotePost) {
        do {
            try repository.resolveConflict(for: post, pickingRemoteRevision: remoteRevision)
            PostCoordinator.shared.didResolveConflict(for: post)
            dismiss?()
        } catch {
            DDLogError("Error resolving conflict picking remote version: \(error)")
        }
        isSaving = false
    }

    private func track(_ event: WPAnalyticsEvent) {
        WPAnalytics.track(event, properties: ["source": source.rawValue])
    }
}

private struct PostVersionView: View {
    let version: PostVersion

    @Binding var selectedVersion: PostVersion?

    private var isSelected: Bool { selectedVersion == version }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
                .foregroundColor(.secondary)
            VStack(alignment: .leading) {
                Text(version.title)
                    .font(.system(.headline))
                    .foregroundStyle(.primary)
                Text(version.dateModifiedString)
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                selectedVersion = isSelected ? nil : version
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
    }
}

private enum PostVersion: Hashable, Identifiable {
    case local(AbstractPost)
    case remote(RemotePost)

    var id: Self {
        return self
    }

    var title: String {
        switch self {
        case .local: return Strings.currentDevice
        case .remote: return Strings.anotherDevice
        }
    }

    var dateModifiedString: String {
        switch self {
        case .local(let post):
            return (post.dateModified ?? Date.now).mediumStringWithTime()
        case .remote(let remoteRevision):
            return remoteRevision.dateModified.mediumStringWithTime()
        }
    }
}

final class ResolveConflictViewController: UIHostingController<ResolveConflictView> {

    init(post: AbstractPost, remoteRevision: RemotePost, repository: PostRepository, source: ResolveConflictView.Source) {
        super.init(rootView: .init(post: post, remoteRevision: remoteRevision, repository: repository, source: source))
        rootView.dismiss = { self.dismiss(animated: true) }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Strings {
    enum Navigation {
        static let title = NSLocalizedString(
            "resolveConflict.navigation.title",
            value: "Resolve Conflict",
            comment: "Title for the Resolve Conflict screen."
        )
        static let cancel = NSLocalizedString(
            "resolveConflict.navigation.cancel",
            value: "Cancel",
            comment: "Title for the cancel button on the Resolve Conflict screen."
        )
        static let save = NSLocalizedString(
            "resolveConflict.navigation.save",
            value: "Save",
            comment: "Title for the save button on the Resolve Conflict screen."
        )
    }

    static let description = NSLocalizedString(
        "resolveConflict.description",
        value: "The post was modified on another device. Please select the version of the post to keep.",
        comment: "Description for the Resolve Conflict screen."
    )
    static let currentDevice = NSLocalizedString(
        "resolveConflict.currentDevice",
        value: "Current device",
        comment: "A version of the post on the current device."
    )
    static let anotherDevice = NSLocalizedString(
        "resolveConflict.anotherDevice",
        value: "Another device",
        comment: "A version of the post on another device."
    )
}
