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

        let expectedParams = ["who" : "authors"]
        blogServiceRemote.checkMultiAuthorWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getUsers")
        XCTAssertTrue(checkParametersArray(mockApi.parametersPassedIn, expected: expectedParams),
                      "\(expectedParams) not found in the parameter list")
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

        blogServiceRemote.syncPostTypesWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getPostTypes")
        XCTAssertTrue(checkParametersArray(mockApi.parametersPassedIn, expected: nil),
                      "Default parameters not found in the parameter list")
    }

    func testSingleSyncPostTypes() {

        let name = "name"
        let response = [1 : [name : name]]
        var remotePost = [RemotePostType]()
        blogServiceRemote.syncPostTypesWithSuccess({
            remotePost = $0
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remotePost.count, 1)
        XCTAssertEqual(remotePost[0].name, name)
    }

    func testMultipleSyncPostTypes() {

        let name = "name"
        let response = ["1" : [name : name], "2" : [ name : name]]
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

        let expectedParams = ["show-supported" : "1"]
        blogServiceRemote.syncPostFormatsWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getPostFormats")
        XCTAssertTrue(checkParametersArray(mockApi.parametersPassedIn, expected: expectedParams),
                      "\(expectedParams) not found in the parameter list")
    }

    func testSyncPostFormatsAsArray() {

        let response = ["supported" : ["f1", "f2", "f3"],
                        "all" : ["f1" : "a" , "f2" : "b", "f3" : "c", "f4" : "d", "standard" : "e"]]
        var responseFormats = [NSObject : NSObject]()
        blogServiceRemote.syncPostFormatsWithSuccess({
            if let formats = $0 as? [NSObject : NSObject] {
                responseFormats = formats
            }
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(responseFormats["f1"], "a")
        XCTAssertEqual(responseFormats["f2"], "b")
        XCTAssertEqual(responseFormats["f3"], "c")
        XCTAssertEqual(responseFormats.count, 4)
    }

    func testSyncPostFormatsAsDictionary() {

        let response = ["supported" : [1 : "f1", 2 : "f2", 3 : "f3"],
                        "all" : ["f1" : "a" , "f2" : "b", "f3" : "c", "f4" : "d", "standard" : "e"]]
        var responseFormats = [NSObject : NSObject]()
        blogServiceRemote.syncPostFormatsWithSuccess({
            if let formats = $0 as? [NSObject : NSObject] {
                responseFormats = formats
            }
            }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(responseFormats["f1"], "a")
        XCTAssertEqual(responseFormats["f2"], "b")
        XCTAssertEqual(responseFormats["f3"], "c")
        XCTAssertEqual(responseFormats.count, 4)
    }

    func testSyncSettingRequest() {

        blogServiceRemote.syncSettingsWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getOptions")
        XCTAssertTrue(checkParametersArray(mockApi.parametersPassedIn, expected: nil),
                      "Default parameters not found in the parameter list")
    }

    func testSyncSetting() {

        let name = "name"
        let response = ["blog_title" : ["value" : name]]
        var remoteBlogSettings: RemoteBlogSettings? = nil
        blogServiceRemote.syncSettingsWithSuccess({
            remoteBlogSettings = $0
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(remoteBlogSettings?.name, name)
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

        let expectedParams = ["blog_title" : "name", "blog_tagline" : "tagline"]
        blogServiceRemote.updateBlogSettings(remoteBlogSettings, success: nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.setOptions")
        XCTAssertTrue(checkParametersArray(mockApi.parametersPassedIn, expected: expectedParams),
                      "\(expectedParams) not found in the parameter list")
    }

    func testUpdateBlogSettings() {

        let remoteBlogSettings = RemoteBlogSettings()
        remoteBlogSettings.name = "name"
        remoteBlogSettings.tagline = "tagline"

        let response = ["blog_title" : ["value" : "name"]]
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

        let response = [["blog_title" : ["value" : "name"]]]
        var fail = false
        blogServiceRemote.updateBlogSettings(remoteBlogSettings, success: nil, failure: { _ in
            fail = true
        })
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(fail)
    }

    func testSyncOptionsRequest() {

        blogServiceRemote.syncOptionsWithSuccess(nil, failure: nil)
        XCTAssertEqual(mockApi.methodPassedIn, "wp.getOptions")
        XCTAssertTrue(checkParametersArray(mockApi.parametersPassedIn, expected: nil),
                      "Default parameters not found")
    }

    func testSyncOptions() {

        let response = ["option" : ["a" : "b"]]
        var remoteOptions = [NSObject : NSObject]()
        blogServiceRemote.syncOptionsWithSuccess({
            if let options = $0 as? [NSObject : NSObject] {
                remoteOptions = options
            }
        }, failure: nil)
        mockApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertEqual(response, remoteOptions)
    }

    func testRemotePostFromXMLDictionary() {

        let name = "name"
        let label = "label"
        let apiQueryable = NSNumber(integer: 1)
        let response = [name: name, label: label, "public": apiQueryable]
        let remotePost = blogServiceRemote.remotePostTypeFromXMLRPCDictionary(response)
        XCTAssertEqual(remotePost.name, name)
        XCTAssertEqual(remotePost.label, label)
        XCTAssertEqual(remotePost.apiQueryable, apiQueryable)
    }

    func testRemoteBlogFromXMLDictionary() {

        let name = "name"
        let tagline = "tagline"
        let privacy = 1
        let response = ["blog_title" : ["value" : name],
                        "blog_tagline" : ["value" : tagline],
                        "blog_public" : ["value" : privacy]]
        let remoteBlogSettings = blogServiceRemote.remoteBlogSettingFromXMLRPCDictionary(response)
        XCTAssertEqual(remoteBlogSettings.name, name)
        XCTAssertEqual(remoteBlogSettings.tagline, tagline)
        XCTAssertEqual(remoteBlogSettings.privacy, privacy)
    }

    func checkParametersArray(passedIn: [AnyObject]?, expected: AnyObject?) -> Bool {

        var fullExpectedParams = blogServiceRemote.defaultXMLRPCArguments()
        if let e = expected {
            fullExpectedParams.append(e)
        }

        guard let parametersPassedIn = passedIn as? [NSObject],
            let parametersExpected = fullExpectedParams as? [NSObject] else {
                return false
        }

        let finalSet = Set(parametersPassedIn).subtract(parametersExpected)
        return finalSet.count == 0
    }
}
