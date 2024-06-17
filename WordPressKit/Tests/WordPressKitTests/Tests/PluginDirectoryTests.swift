import XCTest
import OHHTTPStubs
@testable import WordPressKit

class PluginDirectoryTests: XCTestCase {

    func testPluginDirectoryEntryDecodingJetpack() {
        let data = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-jetpack", sender: type(of: self))
        let endpoint = PluginDirectoryGetInformationEndpoint(slug: "jetpack")

        do {
            let plugin = try endpoint.parseResponse(data: data)
            XCTAssertEqual(plugin.name, "Jetpack by WordPress.com")
            XCTAssertEqual(plugin.slug, "jetpack")
            XCTAssertEqual(plugin.version, "5.5.1")
            XCTAssertEqual(plugin.author, "Automattic")
            XCTAssertEqual(plugin.authorURL, URL(string: "https://jetpack.com"))
            XCTAssertNotNil(plugin.icon)
            XCTAssertNotNil(plugin.banner)

        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

    func testPluginDirectoryEntryDecodingRenameXmlrpc() {
        let data =  try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-rename-xml-rpc", sender: type(of: self))
        let endpoint = PluginDirectoryGetInformationEndpoint(slug: "rename-xml-rpc")

        do {
            let plugin = try endpoint.parseResponse(data: data)
            XCTAssertEqual(plugin.name, "Rename XMLRPC")
            XCTAssertEqual(plugin.slug, "rename-xml-rpc")
            XCTAssertEqual(plugin.version, "1.1")
            XCTAssertEqual(plugin.author, "Jorge Bernal")
            XCTAssertEqual(plugin.authorURL, URL(string: "http://koke.me"))
            XCTAssertNil(plugin.icon)
            XCTAssertNil(plugin.banner)
        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

    func testPluginInformationRequest() {
        let endpoint = PluginDirectoryGetInformationEndpoint(slug: "jetpack")
        do {
            let request = try endpoint.buildRequest()
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.wordpress.org/plugins/info/1.0/jetpack.json?fields=icons%2Cbanners")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPluginInformation() async throws {
        let data = try MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-rename-xml-rpc", sender: type(of: self))
        stub(condition: isHost("api.wordpress.org")) { _ in
            HTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let plugin = try await PluginDirectoryServiceRemote().getPluginInformation(slug: "rename-xml-rpc")
        XCTAssertEqual(plugin.name, "Rename XMLRPC")
    }

    func testGetDirectoryFeed() async throws {
        let data = try MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-popular", sender: type(of: self))
        stub(condition: isHost("api.wordpress.org")) { _ in
            HTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let feed = try await PluginDirectoryServiceRemote().getPluginFeed(.popular)
        XCTAssertEqual(feed.plugins.first?.name, "Contact Form 7")
    }

    func testValidateResponseFound() {
        let data = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-rename-xml-rpc", sender: type(of: self))
        let endpoint = PluginDirectoryGetInformationEndpoint(slug: "jetpack")
        do {
            let request = try endpoint.buildRequest()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
            XCTAssertNoThrow(try endpoint.validate(response: response, data: data))
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func testValidateResponseNotFound() {
        let endpoint = PluginDirectoryGetInformationEndpoint(slug: "howdy")

        let request = try! endpoint.buildRequest()
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!

        XCTAssertThrowsError(try endpoint.validate(response: response, data: "null".data(using: .utf8)))
    }

    func testValidatePluginDirectoryFeedResponseSucceeds() throws {
        let endpoint = PluginDirectoryFeedEndpoint(feedType: .popular)

        let request = try endpoint.buildRequest()
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!

        XCTAssertNoThrow(try endpoint.validate(response: response, data: "null".data(using: .utf8)))
    }

    func testValidatePluginDirectoryFeedResponseFails() {
        let endpoint = PluginDirectoryFeedEndpoint(feedType: .popular)

        let request = try! endpoint.buildRequest()
        let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: "1.1", headerFields: nil)!

        XCTAssertThrowsError(try endpoint.validate(response: response, data: "null".data(using: .utf8)))
    }

    func testNewDirectoryFeedRequest() {
        let endpoint = PluginDirectoryFeedEndpoint(feedType: .newest)
        do {
            let request = try endpoint.buildRequest()
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.wordpress.org/plugins/info/1.1/?action=query_plugins&request%5Bbrowse%5D=new&request%5Bfields%5D%5Bbanners%5D=1&request%5Bfields%5D%5Bicons%5D=1&request%5Bfields%5D%5Bsections%5D=0&request%5Bpage%5D=1&request%5Bper_page%5D=50")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPopularDirectoryFeedRequest() {
        let endpoint = PluginDirectoryFeedEndpoint(feedType: .popular)
        do {
            let request = try endpoint.buildRequest()
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.wordpress.org/plugins/info/1.1/?action=query_plugins&request%5Bbrowse%5D=popular&request%5Bfields%5D%5Bbanners%5D=1&request%5Bfields%5D%5Bicons%5D=1&request%5Bfields%5D%5Bsections%5D=0&request%5Bpage%5D=1&request%5Bper_page%5D=50")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPopularDirectoryFeedDecoding() {
        let data = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-popular", sender: type(of: self))
        let endpoint = PluginDirectoryFeedEndpoint(feedType: .popular)

        do {
            let response = try endpoint.parseResponse(data: data)
            XCTAssertEqual(response.pageMetadata.page, 1)
            XCTAssertEqual(response.plugins.count, 50)
            XCTAssertEqual(response.pageMetadata.pluginSlugs.count, 50)
            XCTAssertEqual(response.plugins.first!.name, "Contact Form 7")
            XCTAssertNotNil(response.plugins.first!.icon)

            let slugs = response.plugins.map { $0.slug }
            XCTAssertEqual(response.pageMetadata.pluginSlugs, slugs)

        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

    func testNewDirectoryFeedDecoding() {
        // This also tests parsing the "broken" response where `plugins` is a [Int: Object] Dictionary, instead of an Array.

        let data = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-new", sender: type(of: self))
        let endpoint = PluginDirectoryFeedEndpoint(feedType: .newest)

        do {
            let response = try endpoint.parseResponse(data: data)
            XCTAssertEqual(response.pageMetadata.page, 1)
            XCTAssertEqual(response.plugins.count, 48)
            XCTAssertEqual(response.pageMetadata.pluginSlugs.count, 48)
            XCTAssertEqual(response.plugins.first!.name, "NapoleonCat Chat Widget for Facebook")
            XCTAssertEqual(response.plugins.last!.name, "Woomizer")

            let slugs = response.plugins.map { $0.slug }
            XCTAssertEqual(response.pageMetadata.pluginSlugs, slugs)

        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

    func testPluginDirectoryFeedPageDecoderSucceeds() {
        let data = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-new", sender: type(of: self))

        do {
            let response = try JSONDecoder().decode(PluginDirectoryFeedPage.self, from: data)
            XCTAssertEqual(response.pageMetadata.page, 1)
            XCTAssertEqual(response.plugins.count, 48)
            XCTAssertEqual(response.pageMetadata.pluginSlugs.count, 48)
            XCTAssertEqual(response.plugins.first!.name, "NapoleonCat Chat Widget for Facebook")
            XCTAssertEqual(response.plugins.last!.name, "Woomizer")

            let slugs = response.plugins.map { $0.slug }
            XCTAssertEqual(response.pageMetadata.pluginSlugs, slugs)

        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

    func testPluginFeedPageDirectoryEquatable() {
        let data = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-jetpack", sender: type(of: self))
        let endpoint = PluginDirectoryGetInformationEndpoint(slug: "jetpack")

        do {
            let response = try endpoint.parseResponse(data: data)
            let sameResponse = try endpoint.parseResponse(data: data)
            XCTAssertTrue(response == sameResponse)
        } catch {
            XCTFail("Could not fetch Plugin Directory")
        }
    }

    func testPluginFeedPageDirectoryNotEquatableWithSimilarData() {
        let jetpackData = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-jetpack", sender: type(of: self))
        let jetpackEndpoint = PluginDirectoryGetInformationEndpoint(slug: "jetpack")
        let jetpackBetaData = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-jetpack-beta", sender: type(of: self))
        let jetpackBetaEndpoint = PluginDirectoryGetInformationEndpoint(slug: "jetpack-beta")

        do {
            let jetpackResponse = try jetpackEndpoint.parseResponse(data: jetpackData)
            let betaResponse = try jetpackBetaEndpoint.parseResponse(data: jetpackBetaData)
            XCTAssertNotEqual(jetpackResponse, betaResponse)
        } catch {
            XCTFail("Could not fetch Plugin Directory")
        }
    }

    func testPluginFeedPageDirectoryNotEquatable() {
        let popularData = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-popular", sender: type(of: self))
        let popularEndpoint = PluginDirectoryFeedEndpoint(feedType: .popular)

        let newData = try! MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-new", sender: type(of: self))
        let newEndpoint = PluginDirectoryFeedEndpoint(feedType: .newest)

        do {
            let popularPluginFeedPage = try popularEndpoint.parseResponse(data: popularData)
            let newestPluginFeedPage = try newEndpoint.parseResponse(data: newData)

            XCTAssertFalse(popularPluginFeedPage == newestPluginFeedPage)
        } catch {
            XCTFail("Couldn't decode feed pages")
        }
    }

    func testExtractHTMLTextOutput() {
        let plugin = MockPluginDirectoryProvider.getPluginDirectoryEntry()
        let expectedInstallationText = extractHTMLText(MockPluginDirectoryProvider.getJetpackInstallationHTML())
        let expectedFAQText = extractHTMLText(MockPluginDirectoryProvider.getJetpackFAQHTML())

        XCTAssertEqual(plugin.installationText, expectedInstallationText)
        XCTAssertEqual(plugin.faqText, expectedFAQText)
    }

    func testDirectoryEntryStarRatingOutput() {
        let plugin = MockPluginDirectoryProvider.getPluginDirectoryEntry()

        let starRating = plugin.starRating
        let expected: Double = 4.0

        XCTAssertEqual(starRating, expected)
    }

    func testTrimChangeLogReturnsFirstOccurence() {
        let jetpack = MockPluginDirectoryProvider.getPluginDirectoryEntry()
        let changeLog = jetpack.changelogHTML

        let firstOccurence = trimChangelog(changeLog)
        let expectation = "<h4>5.5.1</h4>\n<ul>\n<li>Release date: November 21, 2017</li>\n<li>Release post: https://wp.me/p1moTy-6Bd</li>\n</ul>\n<p><strong>Bug fixes</strong><br />\n* In Jetpack 5.5 we made some changes that created errors if you were using other plugins that added custom links to the Plugins menu. This is now fixed.<br />\n* We have fixed a problem that did not allow to upload plugins using API requests.<br />\n* Open Graph links in post headers are no longer invalid in some special cases.<br />\n* We fixed warnings happening when syncing users with WordPress.com.<br />\n* We updated the way the Google+ button is loaded to match changes made by Google, to ensure the button is always displayed properly.<br />\n* We fixed conflicts between Jetpack&#8217;s Responsive Videos and the updates made to Video players in WordPress 4.9.<br />\n* We updated Publicize&#8217;s message length to match Twitter&#8217;s new 280 character limit.</p>"

        XCTAssertNotEqual(firstOccurence, expectation)
    }

    func testInitFromResponseObjectOutput() {
        let jetpackPluginMockPath = Bundle(for: type(of: self)).path(forResource: "plugin-directory-jetpack", ofType: "json")!
        let json = JSONLoader().loadFile(jetpackPluginMockPath) as AnyObject
        guard let response = json as? [String: AnyObject] else {
            return
        }

        do {
            let directoryEntry = try PluginDirectoryEntry(responseObject: response)

            XCTAssertEqual(directoryEntry.name, "Jetpack by WordPress.com")
            XCTAssertEqual(directoryEntry.slug, "jetpack")
            XCTAssertEqual(directoryEntry.authorURL, nil)
            XCTAssertEqual(directoryEntry.lastUpdated, nil)
            XCTAssertEqual(directoryEntry.faqText, nil)
        } catch {
            XCTFail("Could not convert plugin \(error)")
        }
    }

    func testEcodeableDecodeableReturnsCorrectly() {
        let plugin = MockPluginDirectoryProvider.getPluginDirectoryEntry()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try! encoder.encode(plugin)
        let decoded = try! decoder.decode(PluginDirectoryEntry.self, from: data)

        XCTAssertEqual(plugin.name, decoded.name)
        XCTAssertEqual(plugin.slug, decoded.slug)
        XCTAssertEqual(plugin.version, decoded.version)
        XCTAssertEqual(plugin.lastUpdated, decoded.lastUpdated)
        XCTAssertEqual(plugin.icon, decoded.icon)
        XCTAssertEqual(plugin.banner, decoded.banner)
        XCTAssertEqual(plugin.author, decoded.author)
        XCTAssertEqual(plugin.authorURL, decoded.authorURL)
        XCTAssertEqual(plugin.descriptionHTML, decoded.descriptionHTML)
        XCTAssertEqual(plugin.installationHTML, decoded.installationHTML)
        XCTAssertEqual(plugin.faqHTML, decoded.faqHTML)
        XCTAssertEqual(trimTags(trimChangelog(plugin.changelogHTML)), decoded.changelogHTML)
        XCTAssertEqual(plugin.rating, decoded.rating)
    }

    func testPluginStateDirectoryEncodeNoThrow() {
        let plugin = MockPluginDirectoryProvider.getPluginDirectoryEntry()
        let encoder = JSONEncoder()

        do {
            XCTAssertNoThrow(try encoder.encode(plugin), "Could not encode plugin to Json")
            _ = try encoder.encode(plugin)
        } catch {
            XCTFail("Convert to JSON Failed")
        }
    }

    func testPluginDirectoryFeedTypeSlugReturn() {
        let pluginDirectoryFeedTypeNewest = PluginDirectoryFeedType.newest.slug
        let pluginDirectoryFeedTypePopular = PluginDirectoryFeedType.popular.slug
        let pluginDirectoryFeedTypeSearch = PluginDirectoryFeedType.search(term: "blocks").slug

        let expectedNewest = "newest"
        let expectedPopular = "popular"
        let expectedSearch = "search:blocks"

        XCTAssertEqual(pluginDirectoryFeedTypeNewest, expectedNewest)
        XCTAssertEqual(pluginDirectoryFeedTypePopular, expectedPopular)
        XCTAssertEqual(pluginDirectoryFeedTypeSearch, expectedSearch)
    }

    func testPluginDirectoryFeedTypeEquatable() {
        let lhs = PluginDirectoryFeedType.newest
        let rhs = PluginDirectoryFeedType.newest

        XCTAssertTrue(lhs == rhs)
    }

    func testUnconventionalPluginSlug() async throws {
        let data = try MockPluginDirectoryProvider.getPluginDirectoryMockData(with: "plugin-directory-rename-xml-rpc", sender: type(of: self))
        stub(condition: isHost("api.wordpress.org")) { _ in
            HTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let _ = try await PluginDirectoryServiceRemote().getPluginInformation(slug: "%-is-not-allowed")
        let _ = try await PluginDirectoryServiceRemote().getPluginInformation(slug: "中文")

        // No assertion needed.
    }
}
