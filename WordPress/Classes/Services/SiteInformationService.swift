typealias SiteInformationServiceCompletion = (Result<SiteInformation>) -> Void

protocol SiteInformationService {
    func information(for: Locale, completion: @escaping SiteInformationServiceCompletion)
}

final class MockSiteInformationService: SiteInformationService {
    func information(for: Locale, completion: @escaping SiteInformationServiceCompletion) {

        let result = Result.success(mockSiteInformation())

        completion(result)
    }

    private func mockSiteInformation() -> SiteInformation {
        let json = Bundle(for: MockSiteInformationService.self).url(forResource: "site-info-need", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        let value = try! jsonDecoder.decode(SiteInformation.self, from: data)
        return value
    }
}
