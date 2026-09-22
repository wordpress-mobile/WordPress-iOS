import SwiftUI

/// Public delegate protocol the app-target picker sheets call into.
/// `MediaLibraryViewModel` conforms internally; the app target only sees
/// this protocol existential via `ExternalMediaPickerOption.sheetContent`.
@MainActor
public protocol ExternalMediaPickerDelegate: AnyObject {
    func didPick(remoteMedia: [ExternalRemoteMedia])
    func didPick(imagePlaygroundFile url: URL, suggestedName: String)
    func didCancel()
}

/// Public extension point that `MediaLibraryView`'s add-menu iterates.
/// `MediaLibraryRouting` constructs one of these per external source the
/// app target wants to offer (Stock Photos, Image Playground).
public struct ExternalMediaPickerOption: Identifiable {
    public let id: String
    public let label: String
    public let systemImage: String
    public let sheetContent: @MainActor (_ delegate: any ExternalMediaPickerDelegate) -> AnyView

    public init(
        id: String,
        label: String,
        systemImage: String,
        sheetContent: @escaping @MainActor (_ delegate: any ExternalMediaPickerDelegate) -> AnyView
    ) {
        self.id = id
        self.label = label
        self.systemImage = systemImage
        self.sheetContent = sheetContent
    }
}
