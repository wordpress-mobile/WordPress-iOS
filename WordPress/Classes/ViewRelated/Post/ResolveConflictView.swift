import SwiftUI
import UIKit
import WordPressKit

struct ResolveConflictView: View {
    let post: AbstractPost
    let remoteRevision: RemotePost
    let repository: PostRepository
    var dismiss: (() -> Void)?

    private var localVersion: PostVersion { .local(post) }
    private var remoteVersion: PostVersion { .remote(remoteRevision) }

    @State private var selectedVersion: PostVersion?

    var body: some View {
        Form {
            Section {
                Text(Strings.description)
                PostVersionView(version: localVersion) {
                    selectedVersion = $0.isSelected ? localVersion : nil
                }
                PostVersionView(version: remoteVersion) {
                    selectedVersion = $0.isSelected ? remoteVersion : nil
                }
            }
        }
        .navigationTitle(Strings.Navigation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Strings.Navigation.cancel) {
                    dismiss?()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Strings.Navigation.save) {
                    guard let selectedVersion else {
                        dismiss?()
                        return
                    }
                    saveSelectedVersion(selectedVersion, post: post, remoteRevision: remoteRevision)
                }.disabled(selectedVersion == nil)
            }
        }
    }

    @MainActor
    private func saveSelectedVersion(_ version: PostVersion, post: AbstractPost, remoteRevision: RemotePost) {
        switch version {
        case .local:
            handleLocalVersionSelected(for: post)
        case .remote:
            handleRemoteVersionSelected(for: post, remoteRevision: remoteRevision)
        }
    }

    private func handleLocalVersionSelected(for post: AbstractPost) {
        Task {
            do {
                try await repository._save(post, overwrite: true)
                dismiss?()
                // Send notification to create revision and update editor
            } catch {
                showError()
            }
        }
    }

    @MainActor
    private func handleRemoteVersionSelected(for post: AbstractPost, remoteRevision: RemotePost) {
        do {
            try repository._resolveConflict(for: post, pickingRemoteRevision: remoteRevision)
            dismiss?()
            // Send notification to create revision and update editor
        } catch {
            showError()
        }
    }

    private func showError() {
        // Show error alert
    }
}

private struct PostVersionView: View {
    let version: PostVersion
    let onVersionSelected: (PostVersionView) -> Void

    @State var isSelected = false

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
                isSelected.toggle()
                onVersionSelected(self)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            Button {
                // Do something
            } label: {
                Image(systemName: "ellipsis")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private enum PostVersion {
    case local(AbstractPost)
    case remote(RemotePost)

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

    init(post: AbstractPost, remoteRevision: RemotePost, repository: PostRepository) {
        super.init(rootView: .init(post: post, remoteRevision: remoteRevision, repository: repository))
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
