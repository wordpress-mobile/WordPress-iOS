import Foundation

public class WireMock {

    public static func URL() -> Foundation.URL {
        let host = ProcessInfo().environment["WIREMOCK_HOST"] ?? "localhost"
        let port = ProcessInfo().environment["WIREMOCK_PORT"] ?? "8282"
        return Foundation.URL(string: "http://\(host):\(port)/")!
    }
}
