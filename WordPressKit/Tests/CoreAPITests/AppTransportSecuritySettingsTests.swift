import XCTest
#if SWIFT_PACKAGE
@testable import CoreAPI
#else
@testable import WordPressKit
#endif

final class AppTransportSecuritySettingsTests: XCTestCase {

    private var exampleURL = URL(string: "https://example.com")!

    func testReturnsTrueIfAllowsLocalNetworkingIsTrue() throws {
        // Given
        let provider = FakeInfoDictionaryObjectProvider(appTransportSecurity: [
            "NSAllowsLocalNetworking": true,
            // This will be ignored
            "NSAllowsArbitraryLoads": true
        ])
        let appTransportSecurity = AppTransportSecuritySettings(provider)

        // When
        let secureAccessOnly = appTransportSecurity.secureAccessOnly(for: exampleURL)

        // Then
        XCTAssertTrue(secureAccessOnly)
    }

    func testReturnsFalseIfAllowsArbitraryLoadsIsTrue() throws {
        // Given
        let provider = FakeInfoDictionaryObjectProvider(appTransportSecurity: [
            "NSAllowsArbitraryLoads": true
        ])
        let appTransportSecurity = AppTransportSecuritySettings(provider)

        // When
        let secureAccessOnly = appTransportSecurity.secureAccessOnly(for: exampleURL)

        // Then
        XCTAssertFalse(secureAccessOnly)
    }

    func testReturnsTrueByDefault() throws {
        // Given
        let provider = FakeInfoDictionaryObjectProvider(appTransportSecurity: nil)
        let appTransportSecurity = AppTransportSecuritySettings(provider)

        // When
        let secureAccessOnly = appTransportSecurity.secureAccessOnly(for: exampleURL)

        // Then
        XCTAssertTrue(secureAccessOnly)
    }

    func testReturnsTrueIfNothingIsDefined() throws {
        // Given
        let provider = FakeInfoDictionaryObjectProvider(appTransportSecurity: [String: Any]())
        let appTransportSecurity = AppTransportSecuritySettings(provider)

        // When
        let secureAccessOnly = appTransportSecurity.secureAccessOnly(for: exampleURL)

        // Then
        XCTAssertTrue(secureAccessOnly)
    }

    func testReturnsFalseIfAllowsInsecureHTTPLoadsIsTrue() throws {
        // Given
        let provider = FakeInfoDictionaryObjectProvider(appTransportSecurity: [
            "NSExceptionDomains": [
                "shiki.me": [
                    "NSExceptionAllowsInsecureHTTPLoads": true
                ]
            ]
        ])
        let appTransportSecurity = AppTransportSecuritySettings(provider)
        let url = try XCTUnwrap(URL(string: "http://shiki.me"))

        // When
        let secureAccessOnly = appTransportSecurity.secureAccessOnly(for: url)

        // Then
        XCTAssertFalse(secureAccessOnly)
    }

    func testReturnsTrueIfAllowsInsecureHTTPLoadsIsNotProvided() throws {
        // Given
        let provider = FakeInfoDictionaryObjectProvider(appTransportSecurity: [
            "NSExceptionDomains": [
                "shiki.me": [String: Any]()
            ],
            // This value will be ignored because there is an exception for shiki.me
            "NSAllowsArbitraryLoads": true
        ])
        let appTransportSecurity = AppTransportSecuritySettings(provider)
        let url = try XCTUnwrap(URL(string: "http://shiki.me"))

        // When
        let secureAccessOnly = appTransportSecurity.secureAccessOnly(for: url)

        // Then
        XCTAssertTrue(secureAccessOnly)
    }
}
