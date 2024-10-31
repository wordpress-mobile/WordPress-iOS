struct SiteInformation {
    let title: String
    let tagLine: String?

    /// if title is nil, then the corresponding SiteInformation value is nil
    init?(title: String?, tagLine: String?) {
        guard let title = title else {
            return nil
        }
        self.title = title
        self.tagLine = tagLine
    }
}

extension SiteInformation: Equatable {
    static func ==(lhs: SiteInformation, rhs: SiteInformation) -> Bool {
        return lhs.title == rhs.title &&
                lhs.tagLine == rhs.tagLine
    }
}
