
typealias SiteVerticalsServiceCompletion = (Result<[SiteVertical]>) -> Void

/// Abstracts obtention of site verticals
protocol SiteVerticalsService {
    func verticals(for: Locale, type: SiteType, completion: @escaping SiteVerticalsServiceCompletion)
}

/// Mock implementation of the SiteVerticalsService
final class MockSiteVerticalsService: SiteVerticalsService {
    func verticals(for: Locale = .current, type: SiteType, completion: @escaping SiteVerticalsServiceCompletion) {
        let result = Result.success(mockVerticals())

        completion(result)
    }

    private func mockVerticals() -> [SiteVertical] {
        return [ SiteVertical(identifier: Identifier(value: "SV 1"), title: "Vertical 1"),
                 SiteVertical(identifier: Identifier(value: "SV 2"), title: "Vertical 2"),
                 SiteVertical(identifier: Identifier(value: "SV 3"), title: "Vertical 3") ]
    }
}
