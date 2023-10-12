import Foundation

struct PlanWizardContentViewModel {
    private let siteCreator: SiteCreator

    var url: URL {
        var components = URLComponents(string: Constants.plansWebAddress)!
        var queryItems: [URLQueryItem] = []

        if let domainSuggestion = siteCreator.address, !domainSuggestion.isFree {
            queryItems.append(.init(name: Constants.paidDomainNameParameter, value: domainSuggestion.domainName))
        }

        components.queryItems = queryItems
        return components.url!
    }


    init(siteCreator: SiteCreator) {
        self.siteCreator = siteCreator
    }

    func isPlanSelected(_ redirectionURL: URL) -> Bool {
        return selectedPlanSlug(from: redirectionURL) != nil
    }

    func selectedPlanId(from url: URL) -> Int? {
        guard let planId = parameterValue(from: url, key: Constants.planIdParameter) else {
            return nil
        }

        return Int(planId)
    }

    func selectedPlanSlug(from url: URL) -> String? {
        return parameterValue(from: url, key: Constants.planSlugParameter)
    }

    enum Constants {
        static let plansWebAddress = "https://wordpress.com/jetpack-app/plans"
        static let planIdParameter = "plan_id"
        static let planSlugParameter = "plan_slug"
        static let paidDomainNameParameter = "paid_domain_name"
    }
}

private extension PlanWizardContentViewModel {
    func parameterValue(from url: URL, key: String) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let planSlug = components.queryItems?.first(where: { $0.name == key })?.value else {
            return nil
        }

        return planSlug
    }
}
