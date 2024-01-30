import Foundation

struct PlanWizardContentViewModel {
    private let siteCreator: SiteCreator

    var url: URL {
        var components = URLComponents(string: Constants.plansWebAddress)!
        var queryItems: [URLQueryItem] = []

        if let domainSuggestion = siteCreator.address, !domainSuggestion.isFree {
            queryItems.append(.init(name: Constants.InputParameter.paidDomainName, value: domainSuggestion.domainName))
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
        guard let planId = parameterValue(from: url, key: Constants.OutputParameter.planId) else {
            return nil
        }

        return Int(planId)
    }

    func selectedPlanSlug(from url: URL) -> String? {
        return parameterValue(from: url, key: Constants.OutputParameter.planSlug)
    }

    func selectedDomainName(from url: URL) -> String? {
        return parameterValue(from: url, key: Constants.OutputParameter.domainName)
    }

    struct Constants {
        static let plansWebAddress = "https://wordpress.com/jetpack-app/plans"

        struct InputParameter {
            static let paidDomainName = "paid_domain_name"
        }

        struct OutputParameter {
            static let planId = "plan_id"
            static let planSlug = "plan_slug"
            static let domainName = "domain_name"
        }
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
