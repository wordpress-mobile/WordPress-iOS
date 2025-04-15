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

final class MockSiteSegmentsService: SiteSegmentsService {
    func siteSegments(completion: @escaping SiteSegmentsServiceCompletion) {
        let result = SiteSegmentsResult.success(mockSiteTypes)

        completion(result)
    }

    lazy var mockSiteTypes: [SiteSegment] = [
        .withShortSubtitle(identifier: 1),
        .withLongSubtitle(identifier: 2),
        .withShortSubtitle(identifier: 3),
        .withShortSubtitle(identifier: 4)
    ]
}

extension SiteSegment {

    static func withShortSubtitle(identifier: Int64) -> Self {
        .init(
            identifier: identifier,
            title: "Blogger",
            subtitle: "Publish a collection of posts",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: "#FF0000",
            mobile: true
        )
    }

    static func withLongSubtitle(identifier: Int64) -> Self {
        .init(
            identifier: identifier,
            title: "Professional",
            subtitle: "Showcase your portfolio, skills or work. Expand this to two rows",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: "#0000FF",
            mobile: true
        )
    }
}
