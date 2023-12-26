import Foundation
import Combine

final class SiteDomainsViewModel: ObservableObject {
    struct Section: Identifiable {
        let id = UUID()
        let title: String?
        let footer: String?
        let card: AllDomainsListCardView.ViewModel
    }

    @Published
    private(set) var sections: [Section]

    init(blog: Blog) {
        self.sections = Self.buildSections(from: blog)
    }

    // MARK: - Sections

    private static func buildSections(from blog: Blog) -> [Section] {
        return buildFreeDomainSection(from: blog) + buildDomainsSections(from: blog)
    }

    private static func buildFreeDomainSection(from blog: Blog) -> [Section] {
        guard let freeDomain = blog.freeDomain else { return [] }

        return [
            Section(
                title: Strings.freeDomainSectionTitle,
                footer: blog.freeDomainIsPrimary ? Strings.primaryDomainDescription : nil,
                card: .init(
                    name: blog.freeSiteAddress,
                    description: nil,
                    status: nil,
                    expiryDate: DomainExpiryDateFormatter.expiryDate(for: freeDomain),
                    isPrimary: freeDomain.isPrimaryDomain
                )
            )
        ]
    }

    private static func buildDomainsSections(from blog: Blog) -> [Section] {
        var sections: [Section] = []
        for (index, domainRepresentation) in blog.domainsList.enumerated() {
            let section = Section(
                title: index == 0 ? Strings.domainsListSectionTitle : nil,
                footer: domainRepresentation.domain.isPrimaryDomain ? Strings.primaryDomainDescription : nil,
                card: .init(
                    name: domainRepresentation.domain.domainName,
                    description: nil,
                    status: nil,
                    expiryDate: DomainExpiryDateFormatter.expiryDate(for: domainRepresentation.domain),
                    isPrimary: domainRepresentation.domain.isPrimaryDomain
                )
            )
            sections.append(section)
        }

        return sections
    }
}

private extension SiteDomainsViewModel {
    enum Strings {
        static let freeDomainSectionTitle = NSLocalizedString("site.domains.freeDomainSection.title",
                                                              value: "Your Free WordPress.com domain",
                                                              comment: "A section title which displays a row with a free WP.com domain")
        static let primaryDomainDescription = NSLocalizedString("site.domains.primaryDomain",
                                                                value: "Your primary site address is what visitors will see in their address bar when visiting your website.",
                                                                comment: "Footer of the primary site section in the Domains Dashboard.")
        static let domainsListSectionTitle: String = NSLocalizedString("site.domains.domainSection.title",
                                                                       value: "Your Site Domains",
                                                                       comment: "Header of the domains list section in the Domains Dashboard.")
    }
}
