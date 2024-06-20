import XCTest
@testable import WordPressKit

class RemoteVideoPressVideoTests: XCTestCase {

    func mockVideoPressMetadata(_ id: String) -> NSDictionary {
        return [
            "title": "VideoPress demo",
            "description": "asd",
            "width": 1280,
            "height": 720,
            "duration": 143700,
            "display_embed": true,
            "allow_download": false,
            "rating": "G",
            "poster": "https://videos.files.wordpress.com/\(id)/videopress2-web2_hd.original.jpg",
            "original": "https://videos.files.wordpress.com/\(id)/videopress2-web2.mov",
            "watermark": "https://wptv.files.wordpress.com/2010/07/wptv.png",
            "bg_color": "",
            "blog_id": 5089392,
            "post_id": 1913,
            "finished": true
        ]
    }

    func testInit() {
        let id = "AbCdE"
        let metadata = mockVideoPressMetadata(id)
        let video = RemoteVideoPressVideo(dictionary: metadata, id: id)
        XCTAssertEqual(video.title, metadata["title"] as? String)
        XCTAssertEqual(video.videoDescription, metadata["description"] as? String)
        XCTAssertEqual(video.width, metadata["width"] as? Int)
        XCTAssertEqual(video.height, metadata["height"] as? Int)
        XCTAssertEqual(video.duration, metadata["duration"] as? Int)
        XCTAssertEqual(video.displayEmbed, metadata["display_embed"] as? Bool)
        XCTAssertEqual(video.allowDownload, metadata["allow_download"] as? Bool)
        XCTAssertEqual(video.rating, metadata["rating"] as? String)
        XCTAssertEqual(video.posterURL, URL(string: metadata["poster"] as! String))
        XCTAssertEqual(video.originalURL, URL(string: metadata["original"] as! String))
        XCTAssertEqual(video.watermarkURL, URL(string: metadata["watermark"] as! String))
        XCTAssertEqual(video.bgColor, metadata["bg_color"] as? String)
        XCTAssertEqual(video.blogId, metadata["blog_id"] as? Int)
        XCTAssertEqual(video.postId, metadata["post_id"] as? Int)
        XCTAssertEqual(video.finished, metadata["finished"] as? Bool)
    }

    func testGetURLWithToken() {
        let id = "AbCdE"
        let metadata = mockVideoPressMetadata(id)
        let token = "videopress-token"
        let video = RemoteVideoPressVideo(dictionary: metadata, id: id)
        let originalURL = video.originalURL!

        video.token = token
        XCTAssertEqual(video.getURLWithToken(url: originalURL), URL(string: "\(originalURL.absoluteString)?metadata_token=\(token)"))

        video.token = nil
        XCTAssertNil(video.getURLWithToken(url: originalURL))
    }

    func testAsDictionary() throws {
        let id = "AbCdE"
        let metadata = mockVideoPressMetadata(id)
        let video = RemoteVideoPressVideo(dictionary: metadata, id: id)
        let dict = video.asDictionary()
        XCTAssertEqual(video.title, dict["title"] as? String)
        XCTAssertEqual(video.videoDescription, dict["description"] as? String)
        XCTAssertEqual(video.width, dict["width"] as? Int)
        XCTAssertEqual(video.height, dict["height"] as? Int)
        XCTAssertEqual(video.duration, dict["duration"] as? Int)
        XCTAssertEqual(video.displayEmbed, dict["displayEmbed"] as? Bool)
        XCTAssertEqual(video.allowDownload, dict["allowDownload"] as? Bool)
        XCTAssertEqual(video.rating, dict["rating"] as? String)
        XCTAssertEqual(video.posterURL?.absoluteString, dict["posterURL"] as? String)
        XCTAssertEqual(video.originalURL?.absoluteString, dict["originalURL"] as? String)
        XCTAssertEqual(video.watermarkURL?.absoluteString, dict["watermarkURL"] as? String)
        XCTAssertEqual(video.bgColor, dict["bgColor"] as? String)
        XCTAssertEqual(video.blogId, dict["blogId"] as? Int)
        XCTAssertEqual(video.postId, dict["postId"] as? Int)
        XCTAssertEqual(video.finished, dict["finished"] as? Bool)
    }
}
