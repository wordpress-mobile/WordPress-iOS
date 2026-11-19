import Foundation
import Testing
@testable import WordPressKit

struct RemoteReaderSimplePostTests {

    @Test
    func featuredImageURLPrefersFeaturedImage() throws {
        let post = try decode(featuredImage: "https://example.com/featured.jpg",
                              featuredMedia: #"{"uri": "https://example.com/media.jpg", "type": "image"}"#)
        #expect(post.featuredImageURL == URL(string: "https://example.com/featured.jpg"))
    }

    @Test
    func featuredImageURLFallsBackToImageMedia() throws {
        let post = try decode(featuredImage: "",
                              featuredMedia: #"{"uri": "https://example.com/media.jpg", "width": 100, "height": 50, "type": "image"}"#)
        #expect(post.featuredImageURL == URL(string: "https://example.com/media.jpg"))
    }

    @Test
    func featuredImageURLIgnoresVideoMedia() throws {
        let post = try decode(featuredImage: "",
                              featuredMedia: #"{"uri": "https://www.youtube.com/embed/abc?version=3", "type": "video"}"#)
        #expect(post.featuredImageURL == nil)
    }

    @Test
    func featuredImageURLIsNilWithoutMedia() throws {
        let post = try decode(featuredImage: "", featuredMedia: "{}")
        #expect(post.featuredImageURL == nil)
    }

    private func decode(featuredImage: String, featuredMedia: String) throws -> RemoteReaderSimplePost {
        let json = """
        {
            "ID": 1,
            "URL": "https://example.com/post",
            "site_ID": 2,
            "is_following": false,
            "title": "Title",
            "author": {"name": "Author"},
            "excerpt": "",
            "site_name": "Site",
            "featured_image": "\(featuredImage)",
            "featured_media": \(featuredMedia),
            "railcar": {"fetch_algo": "read:related:posts:local/7"}
        }
        """
        return try JSONDecoder().decode(RemoteReaderSimplePost.self, from: Data(json.utf8))
    }
}
