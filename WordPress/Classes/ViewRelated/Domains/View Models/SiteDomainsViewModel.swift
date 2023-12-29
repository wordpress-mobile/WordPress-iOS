import Foundation
import WordPressKit
import Combine

final class SiteDomainsViewModel: ObservableObject {
    private let blog: Blog
    private let domainsService: DomainsServiceAllDomainsFetching?

    @Published
    private(set) var state: State = .loading
    private(set) var loadedDomains: [DomainsService.AllDomainsListItem] = []

    init(blog: Blog, domainsService: DomainsServiceAllDomainsFetching?) {
        self.blog = blog
        self.domainsService = domainsService
    }

    func refresh() {
        domainsService?.fetchAllDomains(resolveStatus: true, noWPCOM: true, completion: { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let domains):
                self.loadedDomains = domains
                let sections = Self.buildSections(from: blog, domains: domains)
                self.state = .normal(sections)
            case .failure(let error):
                self.state = .message(self.errorMessageViewModel(from: error))
            }
        })
    }

    private func errorMessageViewModel(from error: Error) -> DomainsStateViewModel {
        return DomainsStateViewModel.errorMessageViewModel(from: error) { [weak self] in
            self?.state = .loading
            self?.refresh()
        }
    }

    // MARK: - Sections

    private static func buildSections(from blog: Blog, domains: [DomainsService.AllDomainsListItem]) -> [Section] {
        return Self.buildFreeDomainSections(from: blog) + Self.buildDomainsSections(from: blog, domains: domains)
    }

    private static func buildFreeDomainSections(from blog: Blog) -> [Section] {
        guard let freeDomain = blog.freeDomain else { return [] }
        return [
            Section(
                title: Strings.freeDomainSectionTitle,
                footer: blog.freeDomainIsPrimary ? Strings.primaryDomainDescription : nil,
                content: .rows([.init(
                    viewModel: .init(
                        name: blog.freeSiteAddress,
                        description: nil,
                        status: nil,
                        expiryDate: DomainExpiryDateFormatter.expiryDate(for: freeDomain),
                        isPrimary: freeDomain.isPrimaryDomain
                    ),
                    navigation: nil)])
            )
        ]
    }

    private static func buildDomainsSections(from blog: Blog, domains: [DomainsService.AllDomainsListItem]) -> [Section] {
        var sections: [Section] = []

        let primaryDomainName = blog.domainsList.first(where: { $0.domain.isPrimaryDomain })?.domain.domainName
        var primaryDomain: DomainsService.AllDomainsListItem?
        var otherDomains: [DomainsService.AllDomainsListItem] = []

        for domain in domains {
            if domain.blogId == blog.dotComID?.intValue {
                if primaryDomainName == domain.domain {
                    primaryDomain = domain
                } else {
                    otherDomains.append(domain)
                }
            }
        }

        if let primaryDomain {
            let section = Section(
                title: Strings.domainsListSectionTitle,
                footer: Strings.primaryDomainDescription,
                content: .rows([.init(
                    viewModel: .init(
                        name: primaryDomain.domain,
                        description: nil,
                        status: primaryDomain.status,
                        expiryDate: AllDomainsListItemViewModel.expiryDate(from: primaryDomain),
                        isPrimary: true
                    ),
                    navigation: navigation(from: primaryDomain)
                )])
            )
            sections.append(section)
        }

        if otherDomains.count > 0 {
            let domainRows = otherDomains.map {
                SiteDomainsViewModel.Section.Row(
                    viewModel: .init(
                        name: $0.domain,
                        description: nil,
                        status: $0.status,
                        expiryDate: AllDomainsListItemViewModel.expiryDate(from: $0),
                        isPrimary: false
                    ),
                    navigation: navigation(from: $0)
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

    private static func navigation(from domain: DomainsService.AllDomainsListItem) -> SiteDomainsViewModel.Section.Row.Navigation {
        return .init(domain: domain.domain, siteSlug: domain.siteSlug, type: domain.type)
    }
}

extension SiteDomainsViewModel {
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

// MARK: - Types

extension SiteDomainsViewModel {
    enum State {
        case normal([Section])
        case loading
        case message(DomainsStateViewModel)
    }

    struct Section: Identifiable {
        enum SectionKind {
            case rows([Row])
            case addDomain
            case upgradePlan
        }

        struct Row: Identifiable {
            struct Navigation: Hashable {
                let domain: String
                let siteSlug: String
                let type: DomainType
                let analyticsSource: String = "site_domains"
            }

            let id = UUID()
            let viewModel: AllDomainsListCardView.ViewModel
            let navigation: Navigation?
        }

        let id = UUID()
        let title: String?
        let footer: String?
        let content: SectionKind
    }

    struct MessageStateViewModel {
        let title: String
        let description: String
        let button: Button?

        struct Button {
            let title: String
            let action: () -> Void
        }
    }
}
