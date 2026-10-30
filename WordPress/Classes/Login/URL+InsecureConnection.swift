import Foundation

extension URL {
    private static let loopbackHosts: Set<String> = ["localhost", "127.0.0.1", "::1"]

    /// Whether sending credentials to this URL would use an unencrypted connection to a remote host.
    ///
    /// Only loopback destinations are exempt. Names like `*.local` (resolved over the LAN via mDNS)
    /// and `*.test` (resolved by whatever DNS the network provides) do not guarantee a local
    /// connection, so they are treated the same as any other remote host.
    var isInsecureConnection: Bool {
        guard scheme?.lowercased() == "http" else {
            return false
        }
        guard let host = host(percentEncoded: false)?.lowercased() else {
            // A scheme of "http" with no parseable host cannot be proven local. Treat it as insecure.
            return true
        }
        return !Self.loopbackHosts.contains(host)
    }
}
