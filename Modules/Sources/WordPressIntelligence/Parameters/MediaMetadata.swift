import Foundation

/// Metadata for generating alt text and captions for media items.
public struct MediaMetadata {
    public let filename: String?
    public let title: String?
    public let caption: String?
    public let description: String?
    public let altText: String?
    public let fileType: String?
    public let dimensions: String?
    public let imageAnalysis: String?

    public init(
        filename: String? = nil,
        title: String? = nil,
        caption: String? = nil,
        description: String? = nil,
        altText: String? = nil,
        fileType: String? = nil,
        dimensions: String? = nil,
        imageAnalysis: String? = nil
    ) {
        self.filename = filename
        self.title = title
        self.caption = caption
        self.description = description
        self.altText = altText
        self.fileType = fileType
        self.dimensions = dimensions
        self.imageAnalysis = imageAnalysis
    }

    var hasContent: Bool {
        return [filename, title, caption, description, altText, fileType, dimensions, imageAnalysis]
            .contains(where: { !($0?.isEmpty ?? true) })
    }
}
