import Foundation
import Combine

final class SiteDomainsViewModel: ObservableObject {
    private let blogService: BlogService
    private let blog: Blog
    private let domainsService: DomainsService?

    @Published
    private(set) var state: State = .loading

    init(blog: Blog, blogService: BlogService) {
        self.blog = blog
        self.blogService = blogService
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        self.domainsService = DomainsService(coreDataStack: ContextManager.shared, wordPressComRestApi: account?.wordPressComRestApi)
    }

    func refresh() {
        domainsService?.fetchAllDomains(resolveStatus: true, noWPCOM: true, completion: { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let domains):
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
                    name: blog.freeSiteAddress,
                    description: nil,
                    status: nil,
                    expiryDate: DomainExpiryDateFormatter.expiryDate(for: freeDomain),
                    isPrimary: freeDomain.isPrimaryDomain
                )])
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
                    name: primaryDomain.domain,
                    description: nil,
                    status: primaryDomain.status,
                    expiryDate: AllDomainsListItemViewModel.expiryDate(from: primaryDomain),
                    isPrimary: true
                )])
            )
            sections.append(section)
        }

        if otherDomains.count > 0 {
            let domainRows = otherDomains.map {
                AllDomainsListCardView.ViewModel(
                    name: $0.domain,
                    description: nil,
                    status: $0.status,
                    expiryDate: AllDomainsListItemViewModel.expiryDate(from: $0),
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

// MARK: - Types

extension SiteDomainsViewModel {
    enum State {
        case normal([Section])
        case loading
        case message(DomainsStateViewModel)
    }

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
