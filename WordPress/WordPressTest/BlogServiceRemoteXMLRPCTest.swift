import XCTest
@testable import WordPress

class BlogServiceRemoteXMLRPCTest: XCTestCase {

    let mockApi = MockWordPressOrgXMLRPCApi()
    var blogServiceRemote: BlogServiceRemoteXMLRPC!

    override func setUp() {
        super.setUp()
        blogServiceRemote = BlogServiceRemoteXMLRPC(api: mockApi, username: "", password: "")
    }

    func testCheckMultiAuthorRequest() {

        var expectedParams = blogServiceRemote.defaultXMLRPCArguments() as! [NSObject]
        expectedParams.append(["who" : "authors"])

        blogServiceRemote.checkMultiAuthorWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getUsers")
        XCTAssertEqual(mockApi.parametersPassedIn as! [NSObject], expectedParams)
    }

    func testIsMultiAuthor() {

        var isMultiAuthor = false
        let response = [["ID" : 2], ["ID" : 3]]
        blogServiceRemote.checkMultiAuthorWithSuccess( {
                isMultiAuthor = $0
            }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(isMultiAuthor)
    }

    func testIsNotMultiAuthor() {

        var isMultiAuthor = true
        let response = [["ID" : 2]]
        blogServiceRemote.checkMultiAuthorWithSuccess( {
            isMultiAuthor = $0
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertFalse(isMultiAuthor)
    }

    func testSyncPostTypesRequest() {

        let expectedParams = blogServiceRemote.defaultXMLRPCArguments() as! [NSObject]
        blogServiceRemote.syncPostTypesWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getPostTypes")
        XCTAssertEqual(mockApi.parametersPassedIn as! [NSObject], expectedParams)
    }

    func testSingleSyncPostTypes() {

        let name = "My Post"
        let label = "My Label"
        let privacy = 10
        let post = postTypeDictionary(name, label: label, privacy: privacy)
        let response = [1 : post]
        var remotePost = [RemotePostType]()
        blogServiceRemote.syncPostTypesWithSuccess({
            remotePost = $0
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remotePost.count, 1)
        XCTAssertEqual(remotePost[0].name, name)
        XCTAssertEqual(remotePost[0].label, label)
        XCTAssertEqual(remotePost[0].apiQueryable, privacy)
    }

    func testMultipleSyncPostTypes() {

        let name = "My Post"
        let post1 = postTypeDictionary(name, label: "label", privacy: 1)
        let post2 = postTypeDictionary(name, label: "label", privacy: 1)

        let response = ["1" : post1, "2" : post2]
        var remotePost = [RemotePostType]()
        blogServiceRemote.syncPostTypesWithSuccess({
            remotePost = $0
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remotePost.count, 2)
        XCTAssertEqual(remotePost[0].name, name)
        XCTAssertEqual(remotePost[1].name, name)
    }

    func testSyncPostTypesFailure() {

        let response = [:]
        var fail = false
        blogServiceRemote.syncPostTypesWithSuccess(nil, failure: { _ in
            fail = true
        })
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(fail)
    }

    func testSyncPostFormatsRequest() {

        var expectedParams = blogServiceRemote.defaultXMLRPCArguments() as! [NSObject]
        expectedParams.append(["show-supported" : "1"])
        blogServiceRemote.syncPostFormatsWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getPostFormats")
        XCTAssertEqual(mockApi.parametersPassedIn as! [NSObject], expectedParams)
    }

    func testSyncPostFormatsAsArray() {

        let response = supportedFileFormatsArray()
        var responseFormats = [String : AnyObject]()
        blogServiceRemote.syncPostFormatsWithSuccess({
            if let formats = $0 as? [String : AnyObject] {
                responseFormats = formats
            }
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(responseFormats["f1"] as? String, "a")
        XCTAssertEqual(responseFormats["f2"] as? String, "b")
        XCTAssertEqual(responseFormats["f3"] as? String, "c")
        XCTAssertEqual(responseFormats.count, 4)
    }

    func testSyncPostFormatsAsDictionary() {

        let response = supportedFileFormatsDictionary()
        var responseFormats = [String : AnyObject]()
        blogServiceRemote.syncPostFormatsWithSuccess({
            if let formats = $0 as?  [String : AnyObject] {
                responseFormats = formats
            }
            }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(responseFormats["f1"] as? String, "a")
        XCTAssertEqual(responseFormats["f2"] as? String, "b")
        XCTAssertEqual(responseFormats["f3"] as? String, "c")
        XCTAssertEqual(responseFormats.count, 4)
    }

    func testSyncSettingRequest() {

        let expectedParams = blogServiceRemote.defaultXMLRPCArguments() as! [NSObject]
        blogServiceRemote.syncSettingsWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getOptions")
        XCTAssertEqual(mockApi.parametersPassedIn as! [NSObject], expectedParams)
    }

    func testSyncSetting() {

        let name = "My Name"
        let tagline = "My tagline"
        let privacy = 20
        let response = blogSettingsDictionary(name, tagline: tagline, privacy: privacy)

        var remoteBlogSettings: RemoteBlogSettings? = nil
        blogServiceRemote.syncSettingsWithSuccess({
            remoteBlogSettings = $0
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remoteBlogSettings?.name, name)
        XCTAssertEqual(remoteBlogSettings?.tagline, tagline)
        XCTAssertEqual(remoteBlogSettings?.privacy, privacy)
    }

    func testSyncSettingArrayResponse() {

        let name = "name"
        let response = [name]
        var fail = false
        blogServiceRemote.syncSettingsWithSuccess(nil, failure: { _ in
            fail = true
        })
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(fail)
    }

    func testUpdateBlogSettingsRequest() {

        let remoteBlogSettings = RemoteBlogSettings()
        remoteBlogSettings.name = "name"
        remoteBlogSettings.tagline = "tagline"

        var expectedParams = blogServiceRemote.defaultXMLRPCArguments() as! [NSObject]
        expectedParams.append(["blog_title" : "name", "blog_tagline" : "tagline"])
        blogServiceRemote.updateBlogSettings(remoteBlogSettings, success: nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.setOptions")
        XCTAssertEqual(mockApi.parametersPassedIn as! [NSObject], expectedParams)
    }

    func testUpdateBlogSettings() {

        let remoteBlogSettings = RemoteBlogSettings()
        remoteBlogSettings.name = "name"
        remoteBlogSettings.tagline = "tagline"

        let response = blogSettingsDictionary(remoteBlogSettings.name!,
                                              tagline: remoteBlogSettings.tagline!,
                                              privacy: 1)
        var success = false
        blogServiceRemote.updateBlogSettings(remoteBlogSettings, success: {
            success = true
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testUpdateBlogSettingsArrayResponse() {

        let remoteBlogSettings = RemoteBlogSettings()
        remoteBlogSettings.name = "name"
        remoteBlogSettings.tagline = "tagline"
        let blogSettingResponse = blogSettingsDictionary(remoteBlogSettings.name!,
                                                         tagline: remoteBlogSettings.tagline!,
                                                         privacy: 1)
        let response = [blogSettingResponse]
        var fail = false
        blogServiceRemote.updateBlogSettings(remoteBlogSettings, success: nil, failure: { _ in
            fail = true
        })
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(fail)
    }

    func testSyncOptionsRequest() {

        let expectedParams = blogServiceRemote.defaultXMLRPCArguments() as! [NSObject]
        blogServiceRemote.syncOptionsWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getOptions")
        XCTAssertEqual(mockApi.parametersPassedIn as! [NSObject], expectedParams)
    }

    func testSyncOptions() {

        let response = ["option" : ["a" : "b"]]
        var remoteOptions = [String : AnyObject]()
        blogServiceRemote.syncOptionsWithSuccess({
            if let options = $0 as? [String : AnyObject] {
                remoteOptions = options
            }
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(NSDictionary(dictionary: response).isEqualToDictionary(remoteOptions))
    }

    func postTypeDictionary(name: String, label: String, privacy: Int) -> [String: AnyObject] {
        return ["name": name,
                "label" : label,
                "public": privacy]
    }

    func blogSettingsDictionary(name: String, tagline: String, privacy: Int) -> [String: AnyObject] {
        return ["blog_title" : ["value" : name],
                "blog_tagline" : ["value" : tagline],
                "blog_public" : ["value" : privacy]]
        }

    func supportedFileFormatsDictionary() -> [String: AnyObject] {
        return ["supported" : ["f1", "f2", "f3"],
                "all" : ["f1" : "a" , "f2" : "b", "f3" : "c", "f4" : "d", "standard" : "e"]]
    }

    func supportedFileFormatsArray() -> [String: AnyObject] {
        return ["supported" : [1 : "f1", 2 : "f2", 3 : "f3"],
                "all" : ["f1" : "a" , "f2" : "b", "f3" : "c", "f4" : "d", "standard" : "e"]]
    }
}
