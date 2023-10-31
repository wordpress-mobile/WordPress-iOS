
@testable import WordPress

final class MockTenorService: TenorService {
    private let resultsCount: Int

    init(resultsCount: Int) {
        self.resultsCount = resultsCount
    }

    override func search(params: TenorSearchParams, completion: @escaping (TenorResultsPage) -> Void) {
        let text = params.text
        guard text.count > 0 else {
            completion(TenorResultsPage.empty())
            return
        }
        DispatchQueue.global().async {
            let mediaResult = (1...self.resultsCount).map { TenorMockDataHelper.createMockMedia(withId: "\($0)") }
            DispatchQueue.main.async {
                let page = TenorResultsPage(results: mediaResult, pageable: nil)
                completion(page)
            }
        }
    }
}
