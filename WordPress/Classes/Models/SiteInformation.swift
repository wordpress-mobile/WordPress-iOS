struct SiteInformation {
    let title: String
    let tagLine: String?
}

extension SiteInformation: Equatable {
    static func ==(lhs: SiteInformation, rhs: SiteInformation) -> Bool {
        return lhs.title == rhs.title &&
                lhs.tagLine == rhs.tagLine
    }
}
