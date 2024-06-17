public struct SessionDetails {
    let deviceId: String
    let platform: String
    let buildNumber: String
    let marketingVersion: String
    let identifier: String
    let osVersion: String
}

extension SessionDetails: Encodable {

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case platform = "platform"
        case buildNumber = "build_number"
        case marketingVersion = "marketing_version"
        case identifier = "identifier"
        case osVersion = "os_version"
    }

    init(deviceId: String, bundle: Bundle = .main) {
        self.deviceId = deviceId
        self.platform = "ios"
        self.buildNumber = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        self.marketingVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.identifier = bundle.bundleIdentifier ?? "Unknown"
        self.osVersion = UIDevice.current.systemVersion
    }

    func dictionaryRepresentation() throws -> [String: AnyObject]? {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: AnyObject]
    }
}
