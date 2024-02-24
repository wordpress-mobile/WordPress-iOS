/// A limited representation of the users Jetpack credentials
public struct JetpackScanCredentials: Decodable {
    public let host: String?
    public let port: Int?
    public let user: String?
    public let path: String?
    public let type: String
    public let role: String
    public let stillValid: Bool
}
