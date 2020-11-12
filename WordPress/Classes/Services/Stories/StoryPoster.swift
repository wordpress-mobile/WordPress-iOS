import Foundation
import UIKit
import AVFoundation
import WordPressKit
import CoreServices

class StoryPoster {

    struct Media {
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
        let mediaFiles: [MediaItem]
    }

    struct MediaItem: Codable {
        let alt: String
        let caption: String
        let id: Double
        let link: String
        let mime: String
        let type: String
        let url: String
    }

    enum StoryPosterError: Error {
        case missingRemotePost // When creation has succeeded but remote post is `nil`
        case missingError // When creation has failed by error is `nil`
    }

    func post(media: [Media], title: String, date: Date = Date(), to blog: Blog, completion: @escaping (Result<Post, Error>) -> Void) {

        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)

        let mediaItems: [MediaItem] = media.map { item in
            return MediaItem(alt: "",
                             caption: "",
                             id: 0,
                             link: "",
                             mime: item.mimeType,
                             type: String(item.mimeType.split(separator: "/").first ?? ""),
                             url: item.url.absoluteString
            )
        }

        post.content = json(items: mediaItems)

        media.forEach { item in
            let asset = item.url as ExportableAsset
            MediaCoordinator.shared.addMedia(from: asset, to: post)
        }

        completion(.success(post))
    }

    func update(post: AbstractPost) {
        let jsonString = post.content

        let decoder = JSONDecoder()
        let mediaItems = try! decoder.decode(Story.self, from: jsonString!.data(using: .utf8)!).mediaFiles

        let newItems: [MediaItem] = mediaItems.map { item in
            let media = post.media.first(where: { mediaItem in
                let itemFilename = URL(string: item.url)?.lastPathComponent.lowercased() ?? ""
                return	 mediaItem.filename?.caseInsensitiveCompare(itemFilename) == .orderedSame
            })!
            return MediaItem(alt: media.alt ?? "",
                             caption: media.caption ?? "",
                             id: media.mediaID?.doubleValue ?? 0,
                             link: media.remoteURL ?? "",
                             mime: media.mimeType() ?? "",
                             type: String(media.mimeType()?.split(separator: "/").first ?? ""),
                             url: media.remoteURL ?? "")

        }

        let mediaJSON = json(items: newItems)
        let content = """
        <!-- wp:jetpack/story
        \(mediaJSON)
        -->
        <div class="wp-story wp-block-jetpack-story"></div>
        <!-- /wp:jetpack/story -->
        """
        post.content = content

        post.status = .publish
        PostCoordinator.shared.save(post)
    }

    private func json(items: [MediaItem]) -> String {
        let story = Story(mediaFiles: items)
        let encoder = JSONEncoder()
        let json = String(data: (try! encoder.encode(story)), encoding: .utf8) ?? ""
        return json
    }

}
