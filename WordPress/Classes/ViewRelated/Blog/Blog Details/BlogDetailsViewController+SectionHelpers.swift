extension Array where Element: BlogDetailsSection {
    fileprivate func findSectionIndex(of category: BlogDetailsSectionCategory) -> Int? {
        return firstIndex(where: { $0.category == category })
    }
}

extension BlogDetailsSubsection {
    fileprivate var sectionCategory: BlogDetailsSectionCategory {
        switch self {
        case .domainCredit:
            return .domainCredit
        case .quickStart:
            return .quickStart
        case .stats, .activity, .jetpackSettings:
            return .jetpack
        case .pages, .posts, .media, .comments:
            return .publish
        case .themes, .customize:
            return .personalize
        case .sharing, .people, .plugins:
            return .configure
        case .home:
            return .home
        @unknown default:
            fatalError()
        }
    }
}

extension BlogDetailsViewController {
    @objc func findSectionIndex(sections: [BlogDetailsSection], category: BlogDetailsSectionCategory) -> Int {
        return sections.findSectionIndex(of: category) ?? NSNotFound
    }

    @objc func sectionCategory(subsection: BlogDetailsSubsection) -> BlogDetailsSectionCategory {
        return subsection.sectionCategory
    }
}
