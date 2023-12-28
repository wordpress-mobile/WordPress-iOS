import Foundation
import Combine

final class SiteDomainsViewModel: ObservableObject {
    struct Section: Identifiable {
        enum SectionKind {
            case rows([AllDomainsListCardView.ViewModel])
            case addDomain
            case upgradePlan
        }

        let id = UUID()
        let title: String?
        let footer: String?
        let content: SectionKind
    }

    private let blogService: BlogService
    private let blog: Blog

    @Published
    private(set) var sections: [Section]

    init(blog: Blog, blogService: BlogService) {
        self.sections = Self.buildSections(from: blog)
        self.blog = blog
        self.blogService = blogService
    }

    func refresh() {
        blogService.refreshDomains(for: blog, success: { [weak self] in
            guard let self else { return }
            self.sections = Self.buildSections(from: blog)
        }, failure: nil)
    }

    // MARK: - Sections

    private static func buildSections(from blog: Blog) -> [Section] {
        return Self.buildFreeDomainSections(from: blog) + Self.buildDomainsSections(from: blog)
    }

    private static func buildFreeDomainSections(from blog: Blog) -> [Section] {
        guard let freeDomain = blog.freeDomain else { return [] }
        return [Section(
            title: Strings.freeDomainSectionTitle,
            footer: blog.freeDomainIsPrimary ? Strings.primaryDomainDescription : nil,
            content: .rows([.init(
                name: blog.freeSiteAddress,
                description: nil,
                status: nil,
                expiryDate: DomainExpiryDateFormatter.expiryDate(for: freeDomain),
                isPrimary: freeDomain.isPrimaryDomain
            )])
        )]
    }

    private static func buildDomainsSections(from blog: Blog) -> [Section] {
        var sections: [Section] = []

        let primaryDomain = blog.domainsList.first(where: { $0.domain.isPrimaryDomain })
        let otherDomains = blog.domainsList.filter { !$0.domain.isPrimaryDomain }

        if let primaryDomain {
            let section = Section(
                title: Strings.domainsListSectionTitle,
                footer: Strings.primaryDomainDescription,
                content: .rows([.init(
                    name: primaryDomain.domain.domainName,
                    description: nil,
                    status: nil,
                    expiryDate: DomainExpiryDateFormatter.expiryDate(for: primaryDomain.domain),
                    isPrimary: primaryDomain.domain.isPrimaryDomain
                )])
            )
            sections.append(section)
        }

        if otherDomains.count > 0 {
            let domainRows = otherDomains.map {
                AllDomainsListCardView.ViewModel(
                    name: $0.domain.domainName,
                    description: nil,
                    status: nil,
                    expiryDate: DomainExpiryDateFormatter.expiryDate(for: $0.domain),
                    isPrimary: false
                )
            }

            let section = Section(
                title: primaryDomain == nil ? Strings.domainsListSectionTitle : nil,
                footer: nil,
                content: .rows(domainRows)
            )

            sections.append(section)
        }

        if sections.count == 0 {
            sections.append(Section(title: nil, footer: nil, content: .upgradePlan))
        } else {
            sections.append(Section(title: nil, footer: nil, content: .addDomain))
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
