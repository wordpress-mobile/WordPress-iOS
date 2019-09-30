import Foundation

class WireMock {
    private static let hostInfoPlistKey = "WIREMOCK_HOST"
    private static let portInfoPlistKey = "WIREMOCK_PORT"

    static func URL() -> Foundation.URL {
        let host = infoPlistEntry(key: hostInfoPlistKey)
        let port = infoPlistEntry(key: portInfoPlistKey)
        return Foundation.URL(string: "http://\(host):\(port)/")!
    }

    private static func infoPlistEntry(key: String) -> String {
        let plistUrl = Bundle(for: WireMock.self).url(forResource: "Info", withExtension: "plist")!
        return NSDictionary(contentsOf: plistUrl)![key] as! String
    }
}
