import Foundation
import UniformTypeIdentifiers

/// Public boundary payload that app-target external pickers (Stock Photos)
/// construct and pass through `ExternalMediaPickerDelegate`. The
/// module's view model converts this to `UploadSource.remoteURL(_)` before
/// enqueueing — keeps the internal `UploadSource` enum out of the public API.
public struct ExternalRemoteMedia: Sendable {
    public let url: URL
    public let suggestedName: String
    public let contentType: UTType
    public let caption: String?

    public init(url: URL, suggestedName: String, contentType: UTType, caption: String?) {
        self.url = url
        self.suggestedName = suggestedName
        self.contentType = contentType
        self.caption = caption
    }
}
