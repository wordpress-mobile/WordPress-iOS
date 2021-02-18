import Foundation
import UIKit
import WordPressKit
import AutomatticTracks

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

    enum StoryPosterError: Error {
        case jsonEncodeError(Error) // JSON from the draft post cannot be decoded. The Error contains the original decoding error
        case jsonDecodeError(Error) // JSON from the draft post cannot be decoded. The Error contains the original decoding error
        case contentDataEncodingError // JSON from the draft post couldn't be converted to utf8 encoded data.
    }

    func upload(assets: [ExportableAsset], post: AbstractPost, completion: @escaping (Result<Post, PostCoordinator.SavingError>) -> Void) -> [Media] {
        return PostCoordinator.shared.upload(assets: assets, to: post as! Post, completion: { result in
            completion(result)
        }).compactMap { return $0 }
    }

    func upload(mediaItems: [MediaItem], post: Post, completion: @escaping (Result<Post, PostCoordinator.SavingError>) -> Void) -> (String, [Media]) {
        let assets = mediaItems.map { item in
            return item.url as ExportableAsset
        }

        let media = upload(assets: assets, post: post, completion: completion)

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
        let json = String(data: try! encoder.encode(story), encoding: .utf8)
        let block = StoryBlock.wrap(json ?? "", includeFooter: true)
        return (block, media)
    }

    static var filePath: URL = {
        let media = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("KanvasMedia")
        try! FileManager.default.createDirectory(at: media, withIntermediateDirectories: true, attributes: nil)
        return media
    }()
}

struct StoryBlock {

    private static let openTag = "<!-- wp:jetpack/story"
    private static let closeTag = "-->"
    private static let footer = """
        <div class="wp-story wp-block-jetpack-story"></div>
        <!-- /wp:jetpack/story -->
        """

    /// Parse a blog post for Story contents.
    /// - Parameter string: The string containing the HTML for a blog post.
    /// - Returns: The JSON of the first story found in the post content as a String (or `nil` if there isn't one).
    static func parse(_ string: String) -> [String] {
        let matches = string.matches(regex: "\(openTag).*\(closeTag)")
        let contents = matches.map { match -> String in
            let stringRange = string.range(from: match.range)
            return String(string[stringRange])
        }
        return contents
    }

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

    static func unwrap(_ string: String) -> String {
        return string.replacingOccurrences(of: openTag, with: "").replacingOccurrences(of: footer, with: "").replacingOccurrences(of: closeTag, with: "")
    }
}
