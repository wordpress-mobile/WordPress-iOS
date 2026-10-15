import Testing
import WordPressKit

@testable import WordPress

struct SiteCreatorFlowTests {
    @Test func shortFlowRequestsBlankSite() {
        let creator = SiteCreator(flow: .short)
        creator.address = makeSuggestion("bluebirdbakery3.wordpress.com", isFree: true)

        let request = creator.build()

        #expect(request.siteCreationFlow == "mobile-blank")
        #expect(request.defaultAnnotationAsPrimaryFallback)
        #expect(request.siteDesign == nil)
        #expect(request.verticalIdentifier == nil)
        #expect(request.isPublic)
        #expect(request.siteURLString == "bluebirdbakery3")
        #expect(!request.findAvailableURL)
    }

    @Test func currentFlowRequestIsUnchanged() {
        let creator = SiteCreator(flow: .current)
        creator.address = makeSuggestion("bluebirdbakery3.wordpress.com", isFree: true)
        creator.vertical = SiteIntentVertical(
            slug: "food",
            localizedTitle: "Food",
            emoji: "🍔",
            isDefault: true,
            isCustom: false
        )

        let request = creator.build()

        #expect(request.siteCreationFlow == nil)
        #expect(!request.defaultAnnotationAsPrimaryFallback)
        #expect(request.siteDesign == "default")
        #expect(request.verticalIdentifier == "food")
        #expect(request.isPublic)
        #expect(request.siteURLString == "bluebirdbakery3")
        #expect(!request.findAvailableURL)
    }

    @Test func creatorDefaultsToCurrentFlow() {
        #expect(SiteCreator().flow == .current)
    }

    private func makeSuggestion(_ domainName: String, isFree: Bool) -> DomainSuggestion {
        DomainSuggestion(domainName: domainName, productID: nil, supportsPrivacy: nil, costString: "", isFree: isFree)
    }
}
