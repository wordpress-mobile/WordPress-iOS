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
        post.content = ""

        media.forEach { item in
            let asset = item.url as ExportableAsset
            MediaCoordinator.shared.addMedia(from: asset, to: post)
        }

        completion(.success(post))
    }

    func update(post: AbstractPost) {
        let mediaItems: [MediaItem] = post.media.compactMap { item in
            return MediaItem(alt: item.alt ?? "",
                             caption: item.caption ?? "",
                             id: item.mediaID?.doubleValue ?? 0,
                             link: item.remoteURL ?? "",
                             mime: item.mimeType() ?? "",
                             type: String(item.mimeType()?.split(separator: "/").first ?? ""),
                             url: item.remoteURL ?? "")
        }
        let story = Story(mediaFiles: mediaItems)
        let encoder = JSONEncoder()
        let json = String(data: (try! encoder.encode(story)), encoding: .utf8) ?? ""
        let content = """
        <!-- wp:jetpack/story
        \(json)
        -->
        <div class="wp-story wp-block-jetpack-story"></div>
        <!-- /wp:jetpack/story -->
        """

        post.content = content
        post.status = .publish
        PostCoordinator.shared.save(post)
    }
}
