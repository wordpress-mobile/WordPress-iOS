import Foundation

struct PlanWizardContentViewModel {
    private let siteCreator: SiteCreator

    var url: URL {
        var components = URLComponents(string: Constants.plansWebAddress)!
        var queryItems: [URLQueryItem] = []

        if let domainSuggestion = siteCreator.address, !domainSuggestion.isFree {
            queryItems.append(.init(name: Constants.paidDomainNameParameter, value: domainSuggestion.domainName))
        }

        queryItems.append(.init(name: Constants.redirectParameter, value: Constants.redirectScheme + "://"))
        components.queryItems = queryItems
        return components.url!
    }


    init(siteCreator: SiteCreator) {
        self.siteCreator = siteCreator
    }

    func isPlanSelected(_ redirectionURL: URL) -> Bool {
        return redirectionURL.scheme == Constants.redirectScheme
    }

    func selectedPlanId(from url: URL) -> Int? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItem = components.queryItems?.first(where: { $0.name == Constants.planIdParameter })?.value,
              let planId = Int(queryItem) else {
            return nil
        }

        return planId
    }

    enum Constants {
        static let plansWebAddress = "https://container-exciting-jennings.calypso.live/jetpack-app-plans" // TODO: Set to WP.COM address
        static let redirectParameter = "redirect_to"
        static let redirectScheme = "jetpackappplans"
        static let planIdParameter = "plan_id"
        static let paidDomainNameParameter = "paid_domain_name"
    }
}
