import WordPressKit

typealias SiteAddressServiceCompletion = (Result<[DomainSuggestion]>) -> Void

protocol SiteAddressService {
    func addresses(for: Locale, completion: @escaping SiteAddressServiceCompletion)
}

final class MockSiteAddressService: SiteAddressService {
    func addresses(for: Locale, completion: @escaping SiteAddressServiceCompletion) {
        let result = Result.success(mockAddresses())

        completion(result)
    }

    private func mockAddresses() -> [DomainSuggestion] {
        return [ DomainSuggestion(name: "ravenclaw.wordpress.com"),
                 DomainSuggestion(name: "ravenclaw.com"),
                 DomainSuggestion(name: "team.ravenclaw.com")]
    }
}

private extension DomainSuggestion {
    init(name: String) {
        try! self.init(json: ["domain_name": name as AnyObject])
    }
}
