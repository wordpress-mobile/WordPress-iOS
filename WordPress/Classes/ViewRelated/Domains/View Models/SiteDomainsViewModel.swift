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
        domainsService?.fetchAllDomains(resolveStatus: true, noWPCOM: false, completion: { [weak self] result in
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
        let wpcomDomains = domains.filter { $0.wpcomDomain }
        let otherDomains = domains.filter { !$0.wpcomDomain }

        return Self.buildFreeDomainSections(from: blog, wpComDomains: wpcomDomains) + Self.buildDomainsSections(from: blog, domains: otherDomains)
    }

    private static func buildFreeDomainSections(from blog: Blog, wpComDomains: [DomainsService.AllDomainsListItem]) -> [Section] {
        let blogWpComDomains = wpComDomains.filter { $0.blogId == blog.dotComID?.intValue }
        guard let freeDomain = blogWpComDomains.count > 1 ? blogWpComDomains.first(where: { $0.isWpcomStagingDomain }) : blogWpComDomains.first else {
            return []
        }

        return [
            Section(
                title: Strings.freeDomainSectionTitle,
                footer: blog.freeDomainIsPrimary ? Strings.primaryDomainDescription : nil,
                content: .rows([.init(
                    viewModel: .init(
                        name: freeDomain.domain,
                        description: nil,
                        status: nil,
                        expiryDate: AllDomainsListItemViewModel.expiryDate(from: freeDomain),
                        isPrimary: blog.freeDomainIsPrimary
                    ),
                    navigation: nil)])
            )
        ]
    }

    private static func buildDomainsSections(from blog: Blog, domains: [DomainsService.AllDomainsListItem]) -> [Section] {
        var sections: [Section] = []

        let primaryDomainName = blog.domainsList.first(where: { $0.domain.isPrimaryDomain })?.domain.domainName
        let blogDomains = domains.filter({ $0.blogId == blog.dotComID?.intValue })
        let primaryDomain = blogDomains.first(where: { primaryDomainName == $0.domain })
        let otherDomains = blogDomains.filter({ primaryDomainName != $0.domain })

        if let primaryDomain {
            let section = Section(
                title: String(format: Strings.domainsListSectionTitle, blog.title ?? blog.freeSiteAddress),
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
                title: primaryDomain == nil ? String(format: Strings.domainsListSectionTitle, blog.title ?? blog.freeSiteAddress) : nil,
                footer: nil,
                content: .rows(domainRows)
            )

            sections.append(section)
        }

        if sections.count == 0 || blog.canRegisterDomainWithPaidPlan {
            sections.append(Section(title: nil, footer: nil, content: .upgradePlan))
        } else {
            sections.append(Section(title: nil, footer: nil, content: .addDomain))
        }

        return sections
    }

    private static func navigation(from domain: DomainsService.AllDomainsListItem) -> SiteDomainsViewModel.Navigation {
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
                                                                       value: "Other domains for %1$@",
                                                                       comment: "Header of the secondary domains list section in the Domains Dashboard. %1$@ is the name of the site.")
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
            let id = UUID()
            let viewModel: AllDomainsListCardView.ViewModel
            let navigation: Navigation?
        }

        let id = UUID()
        let title: String?
        let footer: String?
        let content: SectionKind
    }

    struct Navigation: Hashable {
        let domain: String
        let siteSlug: String
        let type: DomainType
        let analyticsSource: String = "site_domains"
    }
}
