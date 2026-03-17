public struct SiteInformation {
    public let title: String
    public let tagLine: String?

    /// if title is nil, then the corresponding SiteInformation value is nil
    public init?(title: String?, tagLine: String?) {
        guard let title else {
            return nil
        }
        self.title = title
        self.tagLine = tagLine
    }
}

extension SiteInformation: Equatable {
    public static func ==(lhs: SiteInformation, rhs: SiteInformation) -> Bool {
        return lhs.title == rhs.title &&
                lhs.tagLine == rhs.tagLine
    }
}
