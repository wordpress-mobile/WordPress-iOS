import XCTest
@testable import WordPress

class MediaServiceRemoteRESTTests: XCTestCase {

    let mockRemoteApi = MockWordPressComRestApi()
    var mediaServiceRemote: MediaServiceRemoteREST!
    let siteID = 99999

    override func setUp() {
        super.setUp()
        mediaServiceRemote = MediaServiceRemoteREST(wordPressComRestApi: mockRemoteApi, siteID: NSNumber(value: siteID))
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
        mediaServiceRemote.getMediaWithID(id as NSNumber!, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaWithID() {

        let id = 1
        let response = ["ID": id]
        var remoteMedia: RemoteMedia? = nil
        mediaServiceRemote.getMediaWithID(id as NSNumber!, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertNotNil(remoteMedia)
        XCTAssertEqual(remoteMedia?.mediaID.intValue, id)
    }

    func testCreateMediaPath() {

        var progress: Progress? = nil
        let expectedPath = "v1.1/sites/\(siteID)/media/new"
        let media = mockRemoteMedia()
        mediaServiceRemote.uploadMedia(media, progress: &progress, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testCreateMedia() {

        let response = ["media": [["ID": 1]]]
        let media = mockRemoteMedia()
        var progress: Progress? = nil
        var remoteMedia: RemoteMedia? = nil
        mediaServiceRemote.uploadMedia(media, progress: &progress, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(media.mediaID, remoteMedia?.mediaID)
    }

    func testCreateMediaError() {

        let response = ["errors": ["some error"]]
        let media = mockRemoteMedia()
        var progress: Progress? = nil
        var errorDescription = ""
        mediaServiceRemote.uploadMedia(media, progress: &progress, success: nil, failure: {
            errorDescription = ($0?.localizedDescription)!
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(errorDescription, response["errors"]![0])
    }

    func testUpdateMediaPath() {

        let media = mockRemoteMedia()
        let expectedPath = "v1.1/sites/\(siteID)/media/\(media.mediaID!)"
        mediaServiceRemote.update(media, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testUpdateMedia() {

        let response = ["ID": 1]
        let media = mockRemoteMedia()
        var remoteMedia: RemoteMedia? = nil
        mediaServiceRemote.update(media, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(media.mediaID, remoteMedia?.mediaID)
    }

    func testDeleteMediaPath() {
        let media = mockRemoteMedia()
        let expectedPath = "v1.1/sites/\(siteID)/media/\(media.mediaID!)/delete"
        mediaServiceRemote.delete(media, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaLibraryPath() {

        let expectedPath = "v1.1/sites/\(siteID)/media"
        mediaServiceRemote.getMediaLibrary(success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetEmptyMediaLibrary() {

        let response = ["media": []]
        var remoteMedias = [RemoteMedia]()
        mediaServiceRemote.getMediaLibrary(success: { (medias) in
            if let medias = medias as? [RemoteMedia] {
                remoteMedias = medias
            }
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(remoteMedias.isEmpty)
    }

    func testGetSingleMediaLibraries() {

        let response = ["media": [["ID": 2]]]
        var remoteMedias = [RemoteMedia]()
        mediaServiceRemote.getMediaLibrary(success: { (medias) in
            if let medias = medias as? [RemoteMedia] {
                remoteMedias = medias
            }
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(remoteMedias.count, 1)
    }

    func testGetMultipleMediaLibraries() {

        let response = ["media": [["ID": 2], ["ID": 3], ["ID": 4]]]
        var remoteMedias = [RemoteMedia]()
        mediaServiceRemote.getMediaLibrary(success: { (medias) in
            if let medias = medias as? [RemoteMedia] {
                remoteMedias = medias
            }
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(remoteMedias.count, 3)
    }

    func testGetMediaLibraryCountPath() {

        let expectedPath = "v1.1/sites/\(siteID)/media"
        mediaServiceRemote.getMediaLibraryCount(success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaLibraryCount() {

        let expectedCount = 3
        let response = ["found": expectedCount]
        var remoteCount = 0
        mediaServiceRemote.getMediaLibraryCount(success: { (count) in
            remoteCount = count
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(remoteCount, expectedCount)
    }

    func testRemoteMediaJSONParsing() {

        let id = 1
        let url = "http://www.wordpress.com"
        let guid = "http://www.gravatar.com"
        let date = "2016-12-14T22:00:00Z"
        let postID = 2
        let file = "file"
        let mimeType = "img/jpeg"
        let title = "title"
        let caption = "caption"
        let description = "description"
        let height = 321
        let width = 432

        let jsonDictionary: [String : Any] = ["ID": id,
                                                      "URL": url,
                                                      "guid": guid,
                                                      "date": date,
                                                      "post_ID": postID,
                                                      "mime_type": mimeType,
                                                      "file": file,
                                                      "title": title,
                                                      "caption": caption,
                                                      "description": description,
                                                      "height": height,
                                                      "width": width]

        let remoteMedia = mediaServiceRemote.remoteMedia(fromJSONDictionary: jsonDictionary)
        XCTAssertEqual(remoteMedia.mediaID.intValue, id)
        XCTAssertEqual(remoteMedia.url.absoluteString, url)
        XCTAssertEqual(remoteMedia.guid.absoluteString, guid)
        XCTAssertEqual(remoteMedia.date, Date.dateWithISO8601String(date)!)
        XCTAssertEqual(remoteMedia.postID.intValue, postID)
        XCTAssertEqual(remoteMedia.file, file)
        XCTAssertEqual(remoteMedia.mimeType, mimeType)
        XCTAssertEqual(remoteMedia.title, title)
        XCTAssertEqual(remoteMedia.caption, caption)
        XCTAssertEqual(remoteMedia.descriptionText, description)
        XCTAssertEqual(remoteMedia.height.intValue, height)
        XCTAssertEqual(remoteMedia.width.intValue, width)
    }
}
