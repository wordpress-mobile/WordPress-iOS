import Foundation
import UIKit
import WordPressKit
import AutomatticTracks

class StoryPoster {

    struct MediaItem {
        let url: URL
        let size: CGSize

        var mimeType: String {
            return url.mimeType
        }
    }

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
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
    }

    /// Posts the media to a blog with the given parameters.
    /// - Parameters:
    ///   - media: The set of MediaItems which compose the story.
    ///   - title: The title of the story.
    ///   - blog: The blog to publish the post to.
    /// - Returns: A `Result` containing either the created `Post` or an `Error`.
    func post(media: [MediaItem], title: String, to blog: Blog) -> Result<Post, Error> {

        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)

        let mediaFiles: [MediaFile] = media.map { item in
            return MediaFile(alt: "",
                             caption: "",
                             id: 0,
                             link: "",
                             mime: item.mimeType,
                             type: String(item.mimeType.split(separator: "/").first ?? ""),
                             url: item.url.absoluteString
            )
        }

        do {
            post.content = try json(files: mediaFiles)
        } catch let error {
            CrashLogging.logMessage("Failed to encode Story")
            let error = StoryPosterError.jsonEncodeError(error)
            CrashLogging.logError(error)
            return .failure(error)
        }

        media.forEach { item in
            let asset = item.url as ExportableAsset
            MediaCoordinator.shared.addMedia(from: asset, to: post)
        }

        return .success(post)
    }

    /// Updates the Post content with the new media details after they have finished uploading. These values are not known until the post is saved and uploaded.
    /// - Parameter post: The Post to update with the new Media details.
    func update(post: AbstractPost) {
        guard let content = post.content else {
            return
        }

        do {
            let storyJSON = StoryBlock.parse(content)

            guard let jsonData = storyJSON?.data(using: .utf8) else {
                return
            }

            let decoder = JSONDecoder()
            let mediaItems = try decoder.decode(Story.self, from: jsonData).mediaFiles

            let newFiles: [MediaFile] = mediaItems.compactMap { file in
                guard let media = post.media.first(where: { media in
                    match(media: media, mediaFile: file)
                }) else {
                    CrashLogging.logMessage("Failed to find matching Story in draft")
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

            let mediaJSON = try json(files: newFiles)
            post.content = StoryBlock.wrap(mediaJSON)
            post.status = .publish
            PostCoordinator.shared.save(post)
        } catch let error {
            CrashLogging.logMessage("Failed to decode Story")
            let error = StoryPosterError.jsonDecodeError(error)
            CrashLogging.logError(error)
        }
    }

    /// Matches Media and MediaFile based on their filenames.
    /// - Parameters:
    ///   - media: The Media item whose URL's filename (last path component).
    ///   - mediaFile: The MediaFile whose filename should be matched.
    /// - Returns: Whether the Media and MediaFile's filename matches.
    private func match(media: Media, mediaFile: MediaFile) -> Bool {
        let itemFilename = URL(string: mediaFile.url)?.lastPathComponent ?? ""
        return media.filename?.caseInsensitiveCompare(itemFilename) == .orderedSame
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
}

struct StoryBlock {

    private static let openTag = "<!-- wp:jetpack/story"
    private static let closeTag = "-->"

    /// Parse a blog post for Story contents.
    /// - Parameter string: The string containing the HTML for a blog post.
    /// - Returns: The JSON of the first story found in the post content as a String (or `nil` if there isn't one).
    static func parse(_ string: String) -> String? {
        guard let lowerBound = string.range(of: openTag, options: .caseInsensitive)?.upperBound,
              let upperBound = string.range(of: closeTag, options: .caseInsensitive, range: lowerBound..<string.endIndex)?.lowerBound
        else {
            return nil
        }
        return String(string[lowerBound..<upperBound])
    }

    /// Wraps the JSON of a Story into a story block.
    /// - Parameter json: The JSON string to wrap in a story block.
    /// - Returns: The string containing the full Story block.
    static func wrap(_ json: String) -> String {
        let content = """
        \(openTag)
        \(json)
        \(closeTag)
        <div class="wp-story wp-block-jetpack-story"></div>
        <!-- /wp:jetpack/story -->
        """
        return content
    }
}
