import XCTest
@testable import WordPressKit

class MediaServiceRemoteRESTTests: RemoteTestCase, RESTTestable {

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
        remoteMedia.localURL = URL(string: "http://www.wordpress.com")
        remoteMedia.mimeType = "img/jpeg"
        remoteMedia.file = "file_name"
        return remoteMedia
    }

    func testGetMediaWithIDPath() {

        let id = 1
        let expectedPath = mediaServiceRemote.path(forEndpoint: "sites/\(siteID)/media/\(id)", withVersion: ._1_1)
        mediaServiceRemote.getMediaWithID(id as NSNumber, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaWithID() {

        let id = 1
        let response = ["ID": id]
        var remoteMedia: RemoteMedia?
        mediaServiceRemote.getMediaWithID(id as NSNumber, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertNotNil(remoteMedia)
        XCTAssertEqual(remoteMedia?.mediaID?.intValue, id)
    }

    func testCreateMediaPath() {

        var progress: Progress?
        let expectedPath = mediaServiceRemote.path(forEndpoint: "sites/\(siteID)/media/new", withVersion: ._1_1)
        let media = mockRemoteMedia()
        mediaServiceRemote.uploadMedia(media, progress: &progress, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testCreateMedia() {

        let response = ["media": [["ID": 1]]]
        let media = mockRemoteMedia()
        var progress: Progress?
        var remoteMedia: RemoteMedia?
        mediaServiceRemote.uploadMedia(media, progress: &progress, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(media.mediaID, remoteMedia?.mediaID)
    }

    func testCreateMediaError() {

        let response = ["errors": ["some error"]]
        let media = mockRemoteMedia()
        var progress: Progress?
        var errorDescription = ""
        mediaServiceRemote.uploadMedia(media, progress: &progress, success: nil, failure: {
            errorDescription = ($0?.localizedDescription)!
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(errorDescription, response["errors"]![0])
    }

    func testCreateMultipleMedia() {

        let response = ["media": [["ID": 1], ["ID": 1]]]
        let media = [mockRemoteMedia(), mockRemoteMedia()]
        var remoteMedia: [RemoteMedia]?
        mediaServiceRemote.uploadMedia(media, requestEnqueued: { _ in }, success: {
            remoteMedia = $0 as? [RemoteMedia]
        }, failure: { _ in })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(media[0].mediaID, remoteMedia?[0].mediaID)
        XCTAssertEqual(media[1].mediaID, remoteMedia?[1].mediaID)
    }

    func testCreateMultipleMediaError() {

        let response = ["errors": ["some error"]]
        let media = [mockRemoteMedia(), mockRemoteMedia()]
        var errorDescription = ""
        mediaServiceRemote.uploadMedia(media, requestEnqueued: { _ in }, success: { _ in }, failure: {
            errorDescription = ($0?.localizedDescription)!
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(errorDescription, response["errors"]![0])
    }

    func testCreateMultipleMediaErrorDictionary() {

        let response = ["errors": [["error": "upload_error", "message": "some error", "file": "file.jpg"]]]
        let media = [mockRemoteMedia(), mockRemoteMedia()]
        var errorDescription = ""
        mediaServiceRemote.uploadMedia(media, requestEnqueued: { _ in }, success: { _ in }, failure: {
            errorDescription = ($0?.localizedDescription)!
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(errorDescription, response["errors"]![0]["message"])
    }

    func testUpdateMediaPath() {

        let media = mockRemoteMedia()
        let expectedPath = mediaServiceRemote.path(forEndpoint: "sites/\(siteID)/media/\(media.mediaID!)", withVersion: ._1_1)
        mediaServiceRemote.update(media, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testUpdateMediaAlt() {
        let alt = "This is an alternative title"
        let response = ["alt": alt]
        let media = mockRemoteMedia()
        media.alt = alt
        var remoteMedia: RemoteMedia?
        mediaServiceRemote.update(media, success: {
            remoteMedia = $0
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(remoteMedia?.alt, alt)
    }

    func testUpdateMedia() {

        let response = ["ID": 1]
        let media = mockRemoteMedia()
        var remoteMedia: RemoteMedia?
        mediaServiceRemote.update(media, success: {
            remoteMedia = $0
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(media.mediaID, remoteMedia?.mediaID)
    }

    func testDeleteMediaPath() {
        let media = mockRemoteMedia()
        let expectedPath = mediaServiceRemote.path(forEndpoint: "sites/\(siteID)/media/\(media.mediaID!)/delete", withVersion: ._1_1)
        mediaServiceRemote.delete(media, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaLibraryPath() {
        let expectedPath = mediaServiceRemote.path(forEndpoint: "sites/\(siteID)/media", withVersion: ._1_1)
        mediaServiceRemote.getMediaLibrary(pageLoad: nil, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetEmptyMediaLibrary() {

        let response = ["media": []]
        var remoteMedias = [RemoteMedia]()
        mediaServiceRemote.getMediaLibrary(pageLoad: nil, success: { (medias) in
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
        mediaServiceRemote.getMediaLibrary(pageLoad: nil, success: { (medias) in
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
        mediaServiceRemote.getMediaLibrary(pageLoad: nil, success: { (medias) in
            if let medias = medias as? [RemoteMedia] {
                remoteMedias = medias
            }
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertEqual(remoteMedias.count, 3)
    }

    func testGetMediaLibraryCountPath() {

        let expectedPath = mediaServiceRemote.path(forEndpoint: "sites/\(siteID)/media", withVersion: ._1_1)
        mediaServiceRemote.getMediaLibraryCount(forType: nil, withSuccess: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMediaLibraryCountNoType() throws {
        let expectedCount = 3
        let response = ["found": expectedCount]

        var remoteCount = 0
        mediaServiceRemote.getMediaLibraryCount(forType: nil, withSuccess: { (count) in
            remoteCount = count
        }, failure: nil)
        // Note: This needs to be called here, after triggerting the API request, or it won't take effect
        // The behavior seems odd and ought to be researched.
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertEqual(remoteCount, expectedCount)
        let params = try XCTUnwrap(mockRemoteApi.parametersPassedIn as? [String: Any])
        XCTAssertNil(params["mime_type"] as? String)
    }

    func testGetMediaLibraryCountWithType() throws {
        let expectedCount = 3
        let response = ["found": expectedCount]

        var remoteCount = 0
        mediaServiceRemote.getMediaLibraryCount(forType: "a_type", withSuccess: { (count) in
            remoteCount = count
        }, failure: nil)
        // Note: This needs to be called here, after triggerting the API request, or it won't take effect.
        // The behavior seems odd and ought to be researched.
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertEqual(remoteCount, expectedCount)
        let params = try XCTUnwrap(mockRemoteApi.parametersPassedIn as? [String: Any])
        let type = try XCTUnwrap(params["mime_type"] as? String)
        XCTAssertEqual(type, "a_type")
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
        let alt = "alt"
        let height = 321
        let width = 432

        let jsonDictionary: [String: Any] = ["ID": id,
                                                      "URL": url,
                                                      "guid": guid,
                                                      "date": date,
                                                      "post_ID": postID,
                                                      "mime_type": mimeType,
                                                      "file": file,
                                                      "title": title,
                                                      "caption": caption,
                                                      "description": description,
                                                      "alt": alt,
                                                      "height": height,
                                                      "width": width]

        let remoteMedia = MediaServiceRemoteREST.remoteMedia(fromJSONDictionary: jsonDictionary)
        XCTAssertEqual(remoteMedia?.mediaID?.intValue, id)
        XCTAssertEqual(remoteMedia?.url?.absoluteString, url)
        XCTAssertEqual(remoteMedia?.guid?.absoluteString, guid)
        XCTAssertEqual(remoteMedia?.date, Date.dateWithISO8601String(date)!)
        XCTAssertEqual(remoteMedia?.postID?.intValue, postID)
        XCTAssertEqual(remoteMedia?.file, file)
        XCTAssertEqual(remoteMedia?.mimeType, mimeType)
        XCTAssertEqual(remoteMedia?.title, title)
        XCTAssertEqual(remoteMedia?.caption, caption)
        XCTAssertEqual(remoteMedia?.descriptionText, description)
        XCTAssertEqual(remoteMedia?.alt, alt)
        XCTAssertEqual(remoteMedia?.height?.intValue, height)
        XCTAssertEqual(remoteMedia?.width?.intValue, width)
    }

    func testRemoteMediaJSONArrayParsing() {
        let id = 1
        let id2 = 2
        let url = "http://www.wordpress.com"
        let guid = "http://www.gravatar.com"
        let date = "2016-12-14T22:00:00Z"
        let postID = 2
        let file = "file"
        let mimeType = "img/jpeg"
        let title = "title"
        let caption = "caption"
        let description = "description"
        let alt = "alt"
        let height = 321
        let width = 432

        let jsonDictionary1: [String: Any] = ["ID": id,
                                              "URL": url,
                                              "guid": guid,
                                              "date": date,
                                              "post_ID": postID,
                                              "mime_type": mimeType,
                                              "file": file,
                                              "title": title,
                                              "caption": caption,
                                              "description": description,
                                              "alt": alt,
                                              "height": height,
                                              "width": width]

        let jsonDictionary2: [String: Any] = ["ID": id2,
                                               "URL": url,
                                               "guid": guid,
                                               "date": date,
                                               "post_ID": postID,
                                               "mime_type": mimeType,
                                               "file": file,
                                               "title": title,
                                               "caption": caption,
                                               "description": description,
                                               "alt": alt,
                                               "height": height,
                                               "width": width]
        let jsonArray = [jsonDictionary1, jsonDictionary2]

        let remoteMediaArray: [RemoteMedia] = MediaServiceRemoteREST.remoteMedia(fromJSONArray: jsonArray) as! [RemoteMedia]

        XCTAssertEqual(remoteMediaArray[0].mediaID?.intValue, id)
        XCTAssertEqual(remoteMediaArray[0].url?.absoluteString, url)
        XCTAssertEqual(remoteMediaArray[0].guid?.absoluteString, guid)
        XCTAssertEqual(remoteMediaArray[0].date, Date.dateWithISO8601String(date)!)
        XCTAssertEqual(remoteMediaArray[0].postID?.intValue, postID)
        XCTAssertEqual(remoteMediaArray[0].file, file)
        XCTAssertEqual(remoteMediaArray[0].mimeType, mimeType)
        XCTAssertEqual(remoteMediaArray[0].title, title)
        XCTAssertEqual(remoteMediaArray[0].caption, caption)
        XCTAssertEqual(remoteMediaArray[0].descriptionText, description)
        XCTAssertEqual(remoteMediaArray[0].alt, alt)
        XCTAssertEqual(remoteMediaArray[0].height?.intValue, height)
        XCTAssertEqual(remoteMediaArray[0].width?.intValue, width)

        XCTAssertEqual(remoteMediaArray[1].mediaID?.intValue, id2)
        XCTAssertEqual(remoteMediaArray[1].url?.absoluteString, url)
        XCTAssertEqual(remoteMediaArray[1].guid?.absoluteString, guid)
        XCTAssertEqual(remoteMediaArray[1].date, Date.dateWithISO8601String(date)!)
        XCTAssertEqual(remoteMediaArray[1].postID?.intValue, postID)
        XCTAssertEqual(remoteMediaArray[1].file, file)
        XCTAssertEqual(remoteMediaArray[1].mimeType, mimeType)
        XCTAssertEqual(remoteMediaArray[1].title, title)
        XCTAssertEqual(remoteMediaArray[1].caption, caption)
        XCTAssertEqual(remoteMediaArray[1].descriptionText, description)
        XCTAssertEqual(remoteMediaArray[1].alt, alt)
        XCTAssertEqual(remoteMediaArray[1].height?.intValue, height)
        XCTAssertEqual(remoteMediaArray[1].width?.intValue, width)
    }

    func testGetMetadataFromVideoPressIDPath() {
        let id = "AbCDeF"
        let expectedPath = mediaServiceRemote.path(forEndpoint: "videos/\(id)", withVersion: ._1_1)
        mediaServiceRemote.getMetadataFromVideoPressID(id, isSitePrivate: false, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testGetMetadataFromPublicVideoPressIDPath() {
        let id = "AbCDeF"
        // Mock VideoPress metadata response.
        stubRemoteResponse("/videos", filename: "videopress-public-video.json", contentType: .ApplicationHTML)
        let expect = self.expectation(description: "VideoPress metadata is fetched for a public video in a private site")
        let mediaServiceRemote = MediaServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteID))
        mediaServiceRemote.getMetadataFromVideoPressID(id, isSitePrivate: true, success: { metadata in
            expect.fulfill()
            XCTAssertNotNil(metadata)
            XCTAssertEqual(metadata?.id, id)
            XCTAssertNil(metadata?.token)
        }, failure: { _ in
            expect.fulfill()
            XCTFail("This call should be successfull")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetMetadataFromPrivateVideoPressIDPath() {
        let id = "AbCDeF"
        let token = "videopress-token"
        stubRemoteResponse("/videos", filename: "videopress-private-video.json", contentType: .ApplicationHTML)
        stubRemoteResponse("/media/videopress-playback-jwt", filename: "videopress-token.json", contentType: .ApplicationHTML)
        let expect = self.expectation(description: "VideoPress metadata is fetched for a private video in public site")
        let mediaServiceRemote = MediaServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteID))
        mediaServiceRemote.getMetadataFromVideoPressID(id, isSitePrivate: false, success: { metadata in
            expect.fulfill()
            XCTAssertNotNil(metadata)
            XCTAssertEqual(metadata?.id, id)
            XCTAssertEqual(metadata?.token, token)
        }, failure: { _ in
            expect.fulfill()
            XCTFail("This call should be successfull")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetMetadataFromSiteDefaultVideoPressIDPath() {
        let id = "AbCDeF"
        let token = "videopress-token"
        stubRemoteResponse("/videos", filename: "videopress-site-default-video.json", contentType: .ApplicationHTML)
        stubRemoteResponse("/media/videopress-playback-jwt", filename: "videopress-token.json", contentType: .ApplicationHTML)
        let expect = self.expectation(description: "VideoPress metadata is fetched for a site default video in a private site")
        let mediaServiceRemote = MediaServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteID))
        mediaServiceRemote.getMetadataFromVideoPressID(id, isSitePrivate: true, success: { metadata in
            expect.fulfill()
            XCTAssertNotNil(metadata)
            XCTAssertEqual(metadata?.id, id)
            XCTAssertEqual(metadata?.token, token)
        }, failure: { _ in
            expect.fulfill()
            XCTFail("This call should be successfull")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetVideoPressToken() {
        let id = "AbCDeF"
        let token = "videopress-token"
        stubRemoteResponse("/media/videopress-playback-jwt", filename: "videopress-token.json", contentType: .ApplicationHTML)
        let expect = self.expectation(description: "VideoPress token is fetched for a video")
        let mediaServiceRemote = MediaServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteID))
        mediaServiceRemote.getVideoPressToken(id, success: { result in
            expect.fulfill()
            XCTAssertEqual(result, token)
        }, failure: { _ in
            expect.fulfill()
            XCTFail("This call should be successfull")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }
}
