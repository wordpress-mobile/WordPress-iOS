import SwiftUI
import WordPressKit

struct ResolveConflictView: View {
    let currentVersion: PostVersion
    let anotherVersion: PostVersion

    var selectedVersion: PostVersion?

    var body: some View {
        Form {
            Section {
                Text(Strings.description)
                PostVersionView(version: currentVersion)
                PostVersionView(version: anotherVersion)
            }
        }
        .navigationTitle(Strings.Navigation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Strings.Navigation.cancel) {
                    // Cancel
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Strings.Navigation.save) {
                    // Save
                }
            }
        }
    }
}

private struct PostVersionView: View {
    let version: PostVersion
    var isSelected: Bool = false

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
                // Do something
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

enum PostVersion {
    case current(local: AbstractPost)
    case another(remote: RemotePost)

    var title: String {
        switch self {
        case .current: return Strings.currentDevice
        case .another: return Strings.anotherDevice
        }
    }

    var dateModifiedString: String {
        switch self {
        case .current(let local):
            return (local.dateModified ?? Date.now).toMediumString()
        case .another(let remote):
            return remote.dateModified.toMediumString()
        }
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
