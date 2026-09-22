import Foundation
import Testing
@testable import Support

struct UnifiedSupportErrorMessageTests {

    @Test func showsTheMessageOfErrorsThatDescribeThemselves() {
        #expect(LocalizedMockError.somethingSpecific.unifiedSupportMessage == "The site is temporarily unavailable.")
    }

    @Test func showsTheMessageOfFoundationErrors() {
        // URLSession fills this in for the errors it reports
        let error = URLError(
            .notConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )

        #expect(error.unifiedSupportMessage == "The Internet connection appears to be offline.")
    }

    @Test func fallsBackToAGenericMessage() {
        #expect(MockError.failure.unifiedSupportMessage == UnifiedSupportLocalization.genericErrorMessage)
        // Without a message of its own, `localizedDescription` would read "The operation couldn't be completed..."
        #expect(URLError(.unknown).unifiedSupportMessage == UnifiedSupportLocalization.genericErrorMessage)
    }

    @Test(arguments: [UnifiedSupportError.offline, .notLoggedIn])
    func describesItsOwnErrors(_ error: UnifiedSupportError) {
        #expect(error.unifiedSupportMessage == error.errorDescription)
        #expect(error.unifiedSupportMessage != UnifiedSupportLocalization.genericErrorMessage)
    }

    @Test func detectsCancellations() {
        #expect(CancellationError().isUnifiedSupportCancellation)
        #expect(URLError(.cancelled).isUnifiedSupportCancellation)
        #expect(!MockError.failure.isUnifiedSupportCancellation)
        #expect(!UnifiedSupportError.offline.isUnifiedSupportCancellation)
    }
}
