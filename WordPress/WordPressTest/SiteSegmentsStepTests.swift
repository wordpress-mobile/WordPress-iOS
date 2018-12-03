import XCTest
@testable import WordPress

final class SiteSegmentsStepTests: XCTestCase {
    private struct HeaderExpectations {
        static let title = "Tell us what kind of site you'd like to make"
        static let subtitle = "This helps us suggest a solid foundation. But you're never locked in -- all sites evolve!"
    }

    private var step: SiteSegmentsStep?

    override func setUp() {
        super.setUp()
        step = SiteSegmentsStep(creator: SiteCreator(), service: MockSiteSegmentsService())
    }

    override func tearDown() {
        step = nil
        super.tearDown()
    }
}
