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
    let id: Double
    let link: String
    let mime: String
    let type: String
    let url: String

    init(alt: String,
         caption: String,
         id: Double,
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

    init(dictionary: [String: Any]) {
        self.init(alt: dictionary["alt"] as! String,
            caption: dictionary["caption"] as! String,
            id: dictionary["id"] as! Double,
            link: dictionary["link"] as! String,
            mime: dictionary["mime"] as! String,
            type: dictionary["type"] as! String,
            url: dictionary["url"] as! String)
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
    func upload(mediaItems: [MediaItem], post: AbstractPost, completion: @escaping (Result<AbstractPost, PostCoordinator.SavingError>) -> Void) throws -> (String, [Media]) {
        let assets = mediaItems.map { item in
            return item.url as ExportableAsset
        }

        // Uploades the media and notifies upong completion with the updated post.
        let media = PostCoordinator.shared.upload(assets: assets, to: post, completion: { result in
            completion(result)
        }).compactMap { return $0 }

        // Update set of `MediaItem`s with values from the new added uploading `Media`.
        let mediaFiles: [MediaFile] = media.enumerated().map { (idx, media) -> MediaFile in
            return MediaFile(alt: media.alt ?? "",
                             caption: media.caption ?? "",
                             id: Double(media.gutenbergUploadID),
                             link: media.remoteURL ?? "",
                             mime: media.mimeType() ?? "",
                             type: String(media.mimeType()?.split(separator: "/").first ?? ""),
                             url: mediaItems[idx].archive?.absoluteString ?? "")
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
