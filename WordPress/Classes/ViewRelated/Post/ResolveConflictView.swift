import SwiftUI
import UIKit
import WordPressKit

struct ResolveConflictView: View {
    let post: AbstractPost
    let remoteRevision: RemotePost
    var dismiss: (() -> Void)?

    private var currentVersion: PostVersion { .current(post) }
    private var anotherVersion: PostVersion { .another(remoteRevision) }

    @State private var selectedVersion: PostVersion?

    var body: some View {
        Form {
            Section {
                Text(Strings.description)
                PostVersionView(version: currentVersion) {
                    selectedVersion = $0.isSelected ? currentVersion : nil
                }
                PostVersionView(version: anotherVersion) {
                    selectedVersion = $0.isSelected ? anotherVersion : nil
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
                    dismiss?()
                }.disabled(selectedVersion == nil)
            }
        }
    }

    private func saveSelectedVersion(_ version: PostVersion, post: AbstractPost, remoteRevision: RemotePost) {
        switch version {
        case .current:
            // TODO: Re-send POST request with a diff (skip if_not_modified_since to overwrite)
            break
        case .another:
            // TODO: Apply RemotePost to the original version and delete the local revision
            break
        }
    }
}

private struct PostVersionView: View {
    let version: PostVersion
    let onButtonTap: (PostVersionView) -> Void

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
                onButtonTap(self)
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
    case current(AbstractPost)
    case another(RemotePost)

    var title: String {
        switch self {
        case .current: return Strings.currentDevice
        case .another: return Strings.anotherDevice
        }
    }

    var dateModifiedString: String {
        switch self {
        case .current(let post):
            return (post.dateModified ?? Date.now).mediumStringWithTime()
        case .another(let remoteRevision):
            return remoteRevision.dateModified.mediumStringWithTime()
        }
    }
}

final class ResolveConflictViewController: UIHostingController<ResolveConflictView> {

    init(post: AbstractPost, remoteRevision: RemotePost) {
        super.init(rootView: .init(post: post, remoteRevision: remoteRevision))
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
        comment: "A versino of the post on another device."
    )
}
