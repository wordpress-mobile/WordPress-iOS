import XCTest
@testable import WordPress

class MediaServiceRemoteRESTTests: XCTestCase {

    let mockRemoteApi = MockWordPressComRestApi()
    var mediaServiceRemote: MediaServiceRemoteREST!
    let siteID = 99999

    override func setUp() {
        super.setUp()
        mediaServiceRemote = MediaServiceRemoteREST(wordPressComRestApi: mockRemoteApi, siteID: siteID)
    }

    func mockRemoteMedia() -> RemoteMedia {

        let remoteMedia = RemoteMedia()
        remoteMedia.mediaID = 1
        remoteMedia.postID = 2
        remoteMedia.localURL = "http://www.wordpress.com"
        remoteMedia.mimeType = "img/jpeg"
        remoteMedia.file = "file_name"
        return remoteMedia
    }

    func testGetMediaWithIDPath() {

        let id = 1
        let expectedPath = "v1.1/sites/\(siteID)/media/\(id)"
        mediaServiceRemote.getMediaWithID(id, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaWithID() {

        let id = 1
        let response = ["ID" : id]
        var remoteMedia: RemoteMedia? = nil
        mediaServiceRemote.getMediaWithID(id, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertNotNil(remoteMedia)
        XCTAssertEqual(remoteMedia?.mediaID, id)
    }

    func testCreateMediaPath() {

        var progress: NSProgress? = nil
        let expectedPath = "v1.1/sites/\(siteID)/media/new"
        let media = mockRemoteMedia()
        mediaServiceRemote.createMedia(media, progress: &progress, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testCreateMedia() {

        let response = ["media" : [["ID" : 1]]]
        let media = mockRemoteMedia()
        var progress: NSProgress? = nil
        var remoteMedia: RemoteMedia? = nil
        mediaServiceRemote.createMedia(media, progress: &progress, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(media.mediaID, remoteMedia?.mediaID)
    }

    func testCreateMediaError() {

        let response = ["error" : ["some error"]]
        let media = mockRemoteMedia()
        var progress: NSProgress? = nil
        var errorDescription = ""
        mediaServiceRemote.createMedia(media, progress: &progress, success:nil, failure: {
            errorDescription = $0.localizedDescription
        })
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(errorDescription, response["error"]![0])
    }

    func testUpdateMediaPath() {

        let media = mockRemoteMedia()
        let expectedPath = "v1.1/sites/\(siteID)/media/\(media.mediaID)"
        mediaServiceRemote.updateMedia(media, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testUpdateMedia() {

        let response = ["ID" : 1]
        let media = mockRemoteMedia()
        var remoteMedia: RemoteMedia? = nil
        mediaServiceRemote.updateMedia(media, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(media.mediaID, remoteMedia?.mediaID)
    }

    func testGetMediaLibraryPath() {

        let expectedPath = "v1.1/sites/\(siteID)/media"
        mediaServiceRemote.getMediaLibraryWithSuccess(nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetEmptyMediaLibrary() {

        let response = ["media" : []]
        var remoteMedias = [RemoteMedia]()
        mediaServiceRemote.getMediaLibraryWithSuccess({
            if let medias = $0 as? [RemoteMedia] {
                remoteMedias = medias
            }
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(remoteMedias.isEmpty)
    }

    func testGetSingleMediaLibraries() {

        let response = ["media" : [["ID" : 2]]]
        var remoteMedias = [RemoteMedia]()
        mediaServiceRemote.getMediaLibraryWithSuccess({
            if let medias = $0 as? [RemoteMedia] {
                remoteMedias = medias
            }
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remoteMedias.count, 1)
    }

    func testGetMultipleMediaLibraries() {

        let response = ["media" : [["ID" : 2], ["ID" : 3], ["ID" : 4]]]
        var remoteMedias = [RemoteMedia]()
        mediaServiceRemote.getMediaLibraryWithSuccess({
            if let medias = $0 as? [RemoteMedia] {
                remoteMedias = medias
            }
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remoteMedias.count, 3)
    }

    func testGetMediaLibraryCountPath() {

        let expectedPath = "v1.1/sites/\(siteID)/media"
        mediaServiceRemote.getMediaLibraryCountWithSuccess(nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaLibraryCount() {

        let expectedCount = 3
        let response = ["found" : expectedCount]
        var remoteCount = 0
        mediaServiceRemote.getMediaLibraryCountWithSuccess({
            remoteCount = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remoteCount, expectedCount)
    }

    func testRemoteMediaJSONParsing(){

        let id = 1
        let url = "http://www.wordpress.com"
        let guid = "http://www.gravatar.com"
        let date = "04/19/1989T10:20:21"
        let postID = 2
        let file = "file"
        let mimeType = "img/jpeg"
        let title = "title"
        let caption = "caption"
        let description = "description"
        let height = 321
        let width = 432

        let jsonDictionary: [NSString : AnyObject] = ["ID" : id,
                                                      "URL" : url,
                                                      "guid" : guid,
                                                      "date" : date,
                                                      "post_ID" : postID,
                                                      "mime_type" : mimeType,
                                                      "file" : file,
                                                      "title" : title,
                                                      "caption" : caption,
                                                      "description" : description,
                                                      "height" : height,
                                                      "width" : width]

        let remoteMedia = mediaServiceRemote.remoteMediaFromJSONDictionary(jsonDictionary)
        XCTAssertEqual(remoteMedia.mediaID, id)
        XCTAssertEqual(remoteMedia.url.absoluteString, url)
        XCTAssertEqual(remoteMedia.guid.absoluteString, guid)
        XCTAssertEqual(remoteMedia.date, NSDate.dateWithISO8601String(date))
        XCTAssertEqual(remoteMedia.postID, postID)
        XCTAssertEqual(remoteMedia.file, file)
        XCTAssertEqual(remoteMedia.mimeType, mimeType)
        XCTAssertEqual(remoteMedia.title, title)
        XCTAssertEqual(remoteMedia.caption, caption)
        XCTAssertEqual(remoteMedia.descriptionText, description)
        XCTAssertEqual(remoteMedia.height, height)
        XCTAssertEqual(remoteMedia.width, width)
    }
}
