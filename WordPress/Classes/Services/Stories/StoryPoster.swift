import Foundation
import UIKit
import WordPressKit
import AutomatticTracks

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

    struct Story: Codable {
        let mediaFiles: [MediaFile]
    }

    struct MediaFile: Codable {
        let alt: String
        let caption: String
        let id: Double
        let link: String
        let mime: String
        let type: String
        let url: String
    }

    enum StoryPosterError: Error {
        case jsonEncodeError(Error) // JSON from the draft post cannot be decoded. The Error contains the original decoding error
        case jsonDecodeError(Error) // JSON from the draft post cannot be decoded. The Error contains the original decoding error
        case contentDataEncodingError // JSON from the draft post couldn't be converted to utf8 encoded data.
    }

    func upload(assets: [ExportableAsset], post: AbstractPost, completion: @escaping (Result<[Media], Error>) -> Void) -> [Media] {
        var completedMedia = [Media?](repeating: nil, count: assets.count)
        var media = [Media]()
        assets.enumerated().forEach { (idx, asset) in
            guard let upload = MediaCoordinator.shared.addMedia(from: asset, to: post) else { return }
            media.append(upload)
            MediaCoordinator.shared.addObserver({ (item, state) in
                DispatchQueue.main.async {
                    switch state {
                    case .ended:
                        completedMedia[idx] = item
                        if completedMedia.contains(nil) == false {
                            completion(.success(completedMedia.compactMap({ $0 })))
                        }
                    case .failed(error: let error):
                        completion(.failure(error))
                    default:
                        ()
                    }
                }
            }, for: upload)
        }
        return media
    }

    func updateContent(post: Post, media: [Media]) {
        let mediaFiles: [MediaFile] = media.map { media -> MediaFile in
            return MediaFile(alt: media.alt ?? "",
                             caption: media.caption ?? "",
                             id: media.mediaID?.doubleValue ?? 0,
                             link: media.remoteURL ?? "",
                             mime: media.mimeType() ?? "",
                             type: String(media.mimeType()?.split(separator: "/").first ?? ""),
                             url: media.remoteURL ?? "")
        }

        do {
            let mediaJSON = try json(files: mediaFiles)
            if let oldMediaFiles = self.oldMediaFiles {
                let newContent = StoryBlock.wrap(mediaJSON, includeFooter: false)
                let matchingStory = findStory(content: post.content ?? "", mediaFiles: oldMediaFiles)
                post.content = post.content?.replacingOccurrences(of: matchingStory, with: newContent)
            } else {
                let newContent = StoryBlock.wrap(mediaJSON, includeFooter: true)
                post.content = newContent
                try post.managedObjectContext?.save()
            }
        } catch let error {
            WordPressAppDelegate.crashLogging?.logMessage("Failed to encode Story")
            let error = StoryPosterError.jsonEncodeError(error)
            WordPressAppDelegate.crashLogging?.logError(error)
        }
    }

    func move(mediaItems: [MediaItem], to newMedia: [Media]) throws {
        let urls = mediaItems.compactMap { item in
            return item.archive?.deletingPathExtension()
        }

        try zip(urls, newMedia).forEach({ (url, media) in
            let newURL = StoryPoster.filePath.appendingPathComponent("\(media.mediaID?.intValue ?? 0)")
            print("\(url.path) - \(FileManager.default.fileExists(atPath: url.path))")
            print("\(newURL.path) - \(FileManager.default.fileExists(atPath: newURL.path.removingSuffix("\(media.mediaID!.intValue)")))")
            try FileManager.default.moveItem(at: url, to: newURL)
        })
    }

    func upload(mediaItems: [MediaItem], post: Post, completion: @escaping (Result<(Post, [Media]
    ), Error>) -> Void) -> [Media] {
        let assets = mediaItems.map { item in
            return item.url as ExportableAsset
        }

        let media = upload(assets: assets, post: post, completion: { result in
            switch result {
            case .success(let media):
                do {
                    try self.move(mediaItems: mediaItems, to: media)
                }
                catch let error {
                    print("Error moving story files \(error)")
                }
                self.updateContent(post: post, media: media)
                completion(.success((post, media)))
            case .failure(let error):
                completion(.failure(error))
            }
        })

        return media
    }

    func findStory(content: String, mediaFiles: [MediaFile]) -> String {
        let storyJSON = StoryBlock.parse(content)
        return storyJSON.first(where: { story in
            return story.contains("\(Int(mediaFiles.first!.id))")
        })!
    }

    func parseStory(content: String) -> [MediaFile]? {
        let storyJSON = StoryBlock.parse(content)

        let matchingFiles = try! storyJSON.map({ block -> [MediaFile] in
            let blockJSON = StoryBlock.unwrap(block)
            guard let jsonData = blockJSON.data(using: .utf8) else {
                throw StoryPosterError.contentDataEncodingError
            }

            let decoder = JSONDecoder()
            return try! decoder.decode(Story.self, from: jsonData).mediaFiles
        }).first!

        return matchingFiles
    }

    func updateMedia<T: Collection>(content: String, media: T) throws -> String where T.Element == Media {
        guard let mediaFiles = parseStory(content: content) else {
            WordPressAppDelegate.crashLogging?.logMessage("Failed to find matching Story in draft")
            return content
        }

        let urls = mediaFiles.compactMap { item in
            return URL(string: item.url)
        }

        let newFiles: [MediaFile] = mediaFiles.compactMap { file in
            guard let media = media.first(where: { media in
                return match(media: media, mediaFile: file)
            }) else {
                WordPressAppDelegate.crashLogging?.logMessage("Failed to find matching Story in draft")
                return nil
            }
            return MediaFile(alt: media.alt ?? "",
                             caption: media.caption ?? "",
                             id: media.mediaID?.doubleValue ?? 0,
                             link: media.remoteURL ?? "",
                             mime: media.mimeType() ?? "",
                             type: String(media.mimeType()?.split(separator: "/").first ?? ""),
                             url: media.remoteURL ?? "")
        }

        zip(urls, newFiles).forEach({ (url, file) in
            let newURL = StoryPoster.filePath.appendingPathComponent("\(Int(file.id))")
            try! FileManager.default.moveItem(at: url, to: newURL)
        })

        let mediaJSON = try json(files: newFiles)
        return StoryBlock.wrap(mediaJSON, includeFooter: false)
    }

    /// Matches Media and MediaFile based on their filenames.
    /// - Parameters:
    ///   - media: The Media item whose URL's filename (last path component).
    ///   - mediaFile: The MediaFile whose filename should be matched.
    /// - Returns: Whether the Media and MediaFile's filename matches.
    private func match(media: Media, mediaFile: MediaFile) -> Bool {
        let itemFilename = URL(string: mediaFile.url)?.deletingPathExtension().lastPathComponent ?? ""
        let filename = URL(string: media.filename ?? "")?.deletingPathExtension().lastPathComponent ?? ""
        return filename.caseInsensitiveCompare(itemFilename) == .orderedSame
    }

    /// Returns only the Story JSON by fetching it from the Story block.
    /// - Parameter string: The entire post content (HTML).
    /// - Returns: A String of the JSON representing the Jetpack story.
    func json(files: [MediaFile]) throws -> String {
        let story = Story(mediaFiles: files)
        let encoder = JSONEncoder()
        let json = String(data: (try encoder.encode(story)), encoding: .utf8) ?? ""
        return json
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
        return string.replacingOccurrences(of: openTag, with: "").replacingOccurrences(of: closeTag, with: "").replacingOccurrences(of: footer, with: "")
    }
}
