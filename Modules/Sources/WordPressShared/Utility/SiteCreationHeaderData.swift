/// Describes the header information presented to a user during individual steps of Site Creation.
/// This struct is best suited for cases where these values are static (i.e., not retrieved from the server).
///
public struct SiteCreationHeaderData {
    public let title: String
    public let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}
