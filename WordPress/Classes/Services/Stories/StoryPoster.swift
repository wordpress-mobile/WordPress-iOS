import Foundation
import UIKit
import WordPressKit
import AutomatticTracks

/// A type representing the Story block
struct Story: Codable {
    let mediaFiles: [MediaFile]
}

/// The contents of a Story block
struct MediaFile: Codable {
    let alt: String
    let caption: String
    let id: String
    let link: String
    let mime: String
    let type: String
    let url: String

    init(alt: String,
         caption: String,
         id: String,
         link: String,
         mime: String,
         type: String,
         url: String) {
        self.alt = alt
        self.caption = caption
        self.id = id
        self.link = link
        self.mime = mime
        self.type = type
        self.url = url
    }

    init(dictionary: [String: Any]) throws {
        // We must handle both possible types because the Gutenberg `replaceBlock` method seems to be changing the type of this field.
        let id: String
        do {
            id = try dictionary.value(key: CodingKeys.id.stringValue, type: NSNumber.self).stringValue
        } catch {
            id = try dictionary.value(key: CodingKeys.id.stringValue, type: String.self)
        }
        self.init(alt: try dictionary.value(key: CodingKeys.alt.stringValue, type: String.self),
            caption: try dictionary.value(key: CodingKeys.caption.stringValue, type: String.self),
            id: id,
            link: try dictionary.value(key: CodingKeys.link.stringValue, type: String.self),
            mime: try dictionary.value(key: CodingKeys.mime.stringValue, type: String.self),
            type: try dictionary.value(key: CodingKeys.type.stringValue, type: String.self),
            url: try dictionary.value(key: CodingKeys.url.stringValue, type: String.self))
    }

    static func file(from dictionary: [String: Any]) -> MediaFile? {
        do {
            return try self.init(dictionary: dictionary)
        } catch let error {
            DDLogWarn("MediaFile error: \(error)")
            return nil
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    enum ValueError: Error, CustomDebugStringConvertible {
        case missingKey(String)
        case wrongType(String, Any)

        var debugDescription: String {
            switch self {
            case Dictionary.ValueError.missingKey(let key):
                return "Dictionary is missing key: \(key)"
            case Dictionary.ValueError.wrongType(let key, let value):
                return "Dictionary has wrong type for \(key): \(type(of: value))"
            }
        }
    }

    func value<T: Any>(key: String, type: T.Type) throws -> T {
        let value = self[key]
        if let castValue = value as? T {
            return castValue
        } else {
            if let value = value {
                throw ValueError.wrongType(key, value)
            } else {
                throw ValueError.missingKey(key)
            }
        }
    }
}

class StoryPoster {

    struct MediaItem {
        let url: URL
        let size: CGSize
        let archive: URL?
        let original: URL?

        var mimeType: String {
            return url.mimeType
        }
    }

    let context: NSManagedObjectContext
    private let oldMediaFiles: [MediaFile]?

    init(context: NSManagedObjectContext, mediaFiles: [MediaFile]?) {
        self.context = context
        self.oldMediaFiles = mediaFiles
    }

    /// Uploads media to a post and updates the post contents upon completion.
    /// - Parameters:
    ///   - mediaItems: The media items to upload.
    ///   - post: The post to add media items to.
    ///   - completion: Called on completion with the new post or an error.
    /// - Returns: `(String, [Media])` A tuple containing the Block which was added to contain the media and the new uploading Media objects will be returned.
    func add(mediaItems: [MediaItem], post: AbstractPost) throws -> (String, [Media]) {
        let assets = mediaItems.map { item in
            return item.url as ExportableAsset
        }

        // Uploades the media and notifies upong completion with the updated post.
        let media = PostCoordinator.shared.add(assets: assets, to: post).compactMap { return $0 }

        // Update set of `MediaItem`s with values from the new added uploading `Media`.
        let mediaFiles: [MediaFile] = media.enumerated().map { (idx, media) -> MediaFile in
            let item = mediaItems[idx]
            return MediaFile(alt: media.alt ?? "",
                             caption: media.caption ?? "",
                             id: String(media.gutenbergUploadID),
                             link: media.remoteURL ?? "",
                             mime: item.mimeType,
                             type: String(item.mimeType.split(separator: "/").first ?? ""),
                             url: item.archive?.absoluteString ?? "")
        }

        let story = Story(mediaFiles: mediaFiles)
        let encoder = JSONEncoder()
        let json = String(data: try encoder.encode(story), encoding: .utf8)
        let block = StoryBlock.wrap(json ?? "", includeFooter: true)
        return (block, media)
    }

    static var filePath: URL? = {
        do {
            let media = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("KanvasMedia")
            try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true, attributes: nil)
            return media
        } catch let error {
            assertionFailure("Failed to create media file path: \(error)")
            return nil
        }
    }()
}

struct StoryBlock {

    private static let openTag = "<!-- wp:jetpack/story"
    private static let closeTag = "-->"
    private static let footer = """
        <div class="wp-story wp-block-jetpack-story"></div>
        <!-- /wp:jetpack/story -->
        """

    /// Wraps the JSON of a Story into a story block.
    /// - Parameter json: The JSON string to wrap in a story block.
    /// - Returns: The string containing the full Story block.
    static func wrap(_ json: String, includeFooter: Bool) -> String {
        let content = """
        \(openTag)
        \(json)
        \(closeTag)
        \(includeFooter ? footer : "")
        """
        return content
    }
}
