import XCTest
@testable import WordPressKit

class PluginDirectoryTests: XCTestCase {
    
    func testPluginDirectoryEntryDecodingJetpack() {
        let jetpackMockPath = Bundle(for: type(of: self)).path(forResource: "plugin-directory-jetpack", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: jetpackMockPath))
        let remote = PluginDirectoryServiceRemote()

        do {
            let plugin = try remote.pluginEntry(fromData: data)
            XCTAssertEqual(plugin.name, "Jetpack by WordPress.com")
            XCTAssertEqual(plugin.slug, "jetpack")
            XCTAssertEqual(plugin.version, "5.5.1")
            XCTAssertNotNil(plugin.icon)
        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

    func testPluginDirectoryEntryDecodingRenameXmlrpc() {
        let jetpackMockPath = Bundle(for: type(of: self)).path(forResource: "plugin-directory-rename-xml-rpc", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: jetpackMockPath))
        let remote = PluginDirectoryServiceRemote()

        do {
            let plugin = try remote.pluginEntry(fromData: data)
            XCTAssertEqual(plugin.name, "Rename XMLRPC")
            XCTAssertEqual(plugin.slug, "rename-xml-rpc")
            XCTAssertEqual(plugin.version, "1.1")
            XCTAssertNil(plugin.icon)
        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

    func testPluginInformationRequest() {
        let remote = PluginDirectoryServiceRemote()
        do {
            let request = try remote.pluginInformationURLRequest(forSlug: "jetpack")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.wordpress.org/plugins/info/1.0/jetpack.json?fields=icons")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
