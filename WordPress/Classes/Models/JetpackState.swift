@objcMembers class JetpackState: NSObject {
    static let minimumVersionRequired = "3.4.3"

    var siteID: NSNumber?
    var version: String?
    var connectedUsername: String?
    var connectedEmail: String?
    var automatedTransfer: Bool = false

    /// Returns true if Jetpack is installed and activated on the site.
    var isInstalled: Bool {
        return version != nil
    }

    /// Returns true if Jetpack is connected to WordPress.com.
    ///
    /// - Warning: Before Jetpack 3.6, a site might appear connected if it was connected and then disconnected. See https://github.com/Automattic/jetpack/issues/2137
    ///
    var isConnected: Bool {
        guard isInstalled,
            let siteID = siteID,
            siteID.intValue > 0 else {
                return false
        }
        return true
    }

    /// Returns YES if the detected version meets the app requirements.

    /// - SeeAlso: JetpackVersionMinimumRequired
    ///
    var isUpdatedToRequiredVersion: Bool {
        guard let version = version else {
            return false
        }
        return version.compare(JetpackState.minimumVersionRequired, options: .numeric) != .orderedAscending
    }

    override var description: String {
        if isConnected {
            let connectedAs = connectedUsername?.nonEmptyString()
                ?? connectedEmail?.nonEmptyString()
                ?? "UNKNOWN"
            return "🚀✅ Jetpack \(version ?? "unknown") connected as \(connectedAs) with site ID \(siteID?.description ?? "unknown")"
        } else if isInstalled {
            return "🚀❌ Jetpack \(version ?? "unknown") not connected"
        } else {
            return "🚀❔Jetpack not installed"
        }
    }
}
