import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import CoreAPI
#else
@testable import WordPressKit
#endif

class RSDParserTests: XCTestCase {

    func testSuccess() throws {
        // Grabbed from https://developer.wordpress.org/xmlrpc.php?rsd
        let xml = """
            <?xml version="1.0" encoding="UTF-8"?><rsd version="1.0" xmlns="http://archipelago.phrasewise.com/rsd">
                <service>
                    <engineName>WordPress</engineName>
                    <engineLink>https://wordpress.org/</engineLink>
                    <homePageLink>https://developer.wordpress.org</homePageLink>
                    <apis>
                        <api name="WordPress" blogID="1" preferred="true" apiLink="https://developer.wordpress.org/xmlrpc.php" />
                        <api name="Movable Type" blogID="1" preferred="false" apiLink="https://developer.wordpress.org/xmlrpc.php" />
                        <api name="MetaWeblog" blogID="1" preferred="false" apiLink="https://developer.wordpress.org/xmlrpc.php" />
                        <api name="Blogger" blogID="1" preferred="false" apiLink="https://developer.wordpress.org/xmlrpc.php" />
                            <api name="WP-API" blogID="1" preferred="false" apiLink="https://developer.wordpress.org/wp-json/" />
                        </apis>
                </service>
            </rsd>
            """
        let parser = try XCTUnwrap(WordPressRSDParser(xmlString: xml))
        try XCTAssertEqual(parser.parsedEndpoint(), "https://developer.wordpress.org/xmlrpc.php")
    }

    func testWordPressEntryOnly() throws {
        // Grabbed from https://developer.wordpress.org/xmlrpc.php?rsd, but removing all other api links.
        let xml = """
            <?xml version="1.0" encoding="UTF-8"?><rsd version="1.0" xmlns="http://archipelago.phrasewise.com/rsd">
                <service>
                    <engineName>WordPress</engineName>
                    <engineLink>https://wordpress.org/</engineLink>
                    <homePageLink>https://developer.wordpress.org</homePageLink>
                    <apis>
                        <api name="WordPress" blogID="1" preferred="true" apiLink="https://developer.wordpress.org/xmlrpc.php" />
                </service>
            </rsd>
            """
        let parser = try XCTUnwrap(WordPressRSDParser(xmlString: xml))
        try XCTAssertEqual(parser.parsedEndpoint(), "https://developer.wordpress.org/xmlrpc.php")
    }

}
