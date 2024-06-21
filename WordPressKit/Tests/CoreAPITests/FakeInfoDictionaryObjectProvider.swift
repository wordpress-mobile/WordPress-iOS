#if SWIFT_PACKAGE
@testable import CoreAPI
#else
@testable import WordPressKit
#endif

class FakeInfoDictionaryObjectProvider: InfoDictionaryObjectProvider {
    private let appTransportSecurity: [String: Any]?

    init(appTransportSecurity: [String: Any]?) {
        self.appTransportSecurity = appTransportSecurity
    }

    func object(forInfoDictionaryKey key: String) -> Any? {
        if key == "NSAppTransportSecurity" {
            return appTransportSecurity
        }

        return nil
    }
}
