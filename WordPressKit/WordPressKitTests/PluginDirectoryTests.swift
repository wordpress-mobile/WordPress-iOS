import XCTest
@testable import WordPressKit

class PluginDirectoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPluginDirectoryEntryDecodingJetpack() {
        let jetpackMockPath = Bundle(for: type(of: self)).path(forResource: "plugin-directory-jetpack", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: jetpackMockPath))
        let decoder = JSONDecoder()
        do {
            let plugin = try decoder.decode(PluginDirectoryEntry.self, from: data)
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
        let decoder = JSONDecoder()
        do {
            let plugin = try decoder.decode(PluginDirectoryEntry.self, from: data)
            XCTAssertEqual(plugin.name, "Rename XMLRPC")
            XCTAssertEqual(plugin.slug, "rename-xml-rpc")
            XCTAssertEqual(plugin.version, "1.1")
            XCTAssertNil(plugin.icon)
        } catch {
            XCTFail("Failed decoding plugin \(error)")
        }
    }

}
