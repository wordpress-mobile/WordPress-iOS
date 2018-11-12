typealias SiteAddressServiceCompletion = (Result<[SiteAddress]>) -> Void

protocol SiteAddressService {
    func addresses(for: Locale, completion: @escaping SiteAddressServiceCompletion)
}

final class MockSiteAddressService: SiteAddressService {
    func addresses(for: Locale, completion: @escaping SiteAddressServiceCompletion) {
        let result = Result.success(mockAddresses())

        completion(result)
    }

    private func mockAddresses() -> [SiteAddress] {
        return [ SiteAddress(identifier: Identifier(value: "SA 1"), title: "ravenclaw.wordpress.com"),
                 SiteAddress(identifier: Identifier(value: "SA 2"), title: "ravenclaw.com"),
                 SiteAddress(identifier: Identifier(value: "SA 3"), title: "team.ravenclaw.com") ]
    }
}
