import XCTest
import WordPressKit
@testable import WordPress

class SiteDesignSectionLoaderTests: XCTestCase {
    private var remoteDesigns: RemoteSiteDesigns {
        let remoteSiteDesignsPayload =
        """
        {"designs":[{"slug":"about","title":"Site Title","segment_id":4,"categories":[{"slug":"about","title":"About","description":"About","emoji":"👋","order":0}],"demo_url":"https://public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/?language=en","theme":"spearhead","group":["single-page","stable", "test-vertical"],"preview":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/%3Flanguage%3Den?vpw=1200&vph=1602&w=200&h=267","preview_tablet":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/%3Flanguage%3Den?vpw=800&vph=1068&w=200&h=267","preview_mobile":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/%3Flanguage%3Den?vpw=400&vph=534&w=200&h=267"},{"slug":"blog-new","title":"Site Title","segment_id":2,"categories":[{"slug":"blog","title":"Blog","description":"Blog","emoji":"📰","order":2}],"demo_url":"https://public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/?language=en","theme":"spearhead","group":["single-page","stable"],"preview":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/%3Flanguage%3Den?vpw=1200&vph=1602&w=200&h=267","preview_tablet":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/%3Flanguage%3Den?vpw=800&vph=1068&w=200&h=267","preview_mobile":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/%3Flanguage%3Den?vpw=400&vph=534&w=200&h=267"}],"categories":[{"slug":"about","title":"About","description":"About","emoji":"👋","order":0},{"slug":"links","title":"Links","description":"Links","emoji":"🔗","order":1},{"slug":"blog","title":"Blog","description":"Blog","emoji":"📰","order":2}]}
        """
        return try! JSONDecoder().decode(RemoteSiteDesigns.self, from: remoteSiteDesignsPayload.data(using: .utf8)!)
    }

    func testRecommendedSectionForValidVertical() throws {
        let testVertical = SiteIntentVertical(slug: "test-vertical", localizedTitle: "Testing", emoji: "")

        let section = SiteDesignSectionLoader.getSectionForVerticalSlug(
            testVertical,
            remoteDesigns: remoteDesigns
        )

        let unwrappedSection = try XCTUnwrap(section)
        XCTAssertEqual(unwrappedSection.title, "Best for Testing")
        XCTAssertEqual(unwrappedSection.designs.count, 1)
    }

    func testNoRecommendedSectionForInvalidVertical() throws {
        let invalidVertical = SiteIntentVertical(slug: "invalid-vertical", localizedTitle: "Testing", emoji: "")

        let section = SiteDesignSectionLoader.getSectionForVerticalSlug(
            invalidVertical,
            remoteDesigns: remoteDesigns
        )

        XCTAssertNil(section)
    }

    func testAssembleSections() throws {
        let testVertical = SiteIntentVertical(slug: "test-vertical", localizedTitle: "Testing", emoji: "")

        let sections = SiteDesignSectionLoader.assembleSections(
            remoteDesigns: remoteDesigns,
            vertical: testVertical
        )

        XCTAssertEqual(sections.count, 3)
        let recommendedSection = sections[0]
        XCTAssertEqual(recommendedSection.title, "Best for Testing")
        XCTAssertEqual(recommendedSection.categorySlug, "recommended_test-vertical")
        XCTAssertEqual(recommendedSection.thumbnailSize, SiteDesignCategoryThumbnailSize.recommended.value)

        let sectionOne = sections[1]
        XCTAssertEqual(sectionOne.categorySlug, "about")
        XCTAssertEqual(sectionOne.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value)

        let sectionTwo = sections[2]
        XCTAssertEqual(sectionTwo.categorySlug, "blog")
        XCTAssertEqual(sectionTwo.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value)
    }

    func testAssembleSectionsFallback() throws {
        let sections = SiteDesignSectionLoader.assembleSections(
            remoteDesigns: remoteDesigns,
            vertical: nil
        )

        XCTAssertEqual(sections.count, 2)
        let sectionOne = sections[0]
        XCTAssertEqual(sectionOne.categorySlug, "blog")
        XCTAssertEqual(sectionOne.thumbnailSize, SiteDesignCategoryThumbnailSize.recommended.value)

        let sectionTwo = sections[1]
        XCTAssertEqual(sectionTwo.categorySlug, "about")
        XCTAssertEqual(sectionTwo.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value)
    }

}
