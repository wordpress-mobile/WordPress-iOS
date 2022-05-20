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

    /// Tests that a section is returned containing designs that are recommended for a vertical
    func testRecommendedSectionForValidVertical() throws {
        // Given
        let validVertical = SiteIntentVertical(slug: "test-vertical", localizedTitle: "Testing", emoji: "")

        // When
        let section = SiteDesignSectionLoader.getSectionForVerticalSlug(
            validVertical,
            remoteDesigns: remoteDesigns
        )
        let unwrappedSection = try XCTUnwrap(section)

        // Then
        XCTAssertEqual(unwrappedSection.title, "Best for Testing")
        XCTAssertEqual(unwrappedSection.designs.count, 1)
    }

    /// Tests that no section is returned when there are no recommended designs for a vertical
    func testNoRecommendedSectionForInvalidVertical() throws {
        // Given
        let invalidVertical = SiteIntentVertical(slug: "invalid-vertical", localizedTitle: "Testing", emoji: "")

        // When
        let section = SiteDesignSectionLoader.getSectionForVerticalSlug(
            invalidVertical,
            remoteDesigns: remoteDesigns
        )

        // Then
        XCTAssertNil(section)
    }

    /// Tests entire assembly of sections when a recommended vertical is used
    func testAssembleSections() throws {
        // Given
        let testVertical = SiteIntentVertical(slug: "test-vertical", localizedTitle: "Testing", emoji: "")

        // When
        let sections = SiteDesignSectionLoader.assembleSections(
            remoteDesigns: remoteDesigns,
            vertical: testVertical
        )

        // Then
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

    /// Tests entire assembly of sections when there are no matches for a vertical and we fall back to the "Blog" category
    func testAssembleSectionsFallback() throws {
        // When
        let sections = SiteDesignSectionLoader.assembleSections(
            remoteDesigns: remoteDesigns,
            vertical: nil
        )

        // Then
        XCTAssertEqual(sections.count, 2)

        let recommendedSection = sections[0]
        XCTAssertEqual(recommendedSection.title, "Best for Blogging")
        XCTAssertEqual(recommendedSection.categorySlug, "blog")
        XCTAssertEqual(recommendedSection.thumbnailSize, SiteDesignCategoryThumbnailSize.recommended.value)

        let sectionOne = sections[1]
        XCTAssertEqual(sectionOne.categorySlug, "about")
        XCTAssertEqual(sectionOne.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value)
    }

    /// Tests that no recommended section is part of the final assembly when there is no fallback
    func testAssembleSectionsFallbackFailure() throws {
        // Given
        let remoteSiteDesignsWithoutBlogCategoryPayload =
        """
        {"designs":[{"slug":"about","title":"Site Title","segment_id":4,"categories":[{"slug":"about","title":"About","description":"About","emoji":"👋","order":0}],"demo_url":"https://public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/?language=en","theme":"spearhead","group":["single-page","stable", "test-vertical"],"preview":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/%3Flanguage%3Den?vpw=1200&vph=1602&w=200&h=267","preview_tablet":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/%3Flanguage%3Den?vpw=800&vph=1068&w=200&h=267","preview_mobile":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobileaboutlayout.wordpress.com/%3Flanguage%3Den?vpw=400&vph=534&w=200&h=267"},{"slug":"blog-new","title":"Site Title","segment_id":2,"categories":[{"slug":"blog","title":"Blog","description":"Blog","emoji":"📰","order":2}],"demo_url":"https://public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/?language=en","theme":"spearhead","group":["single-page","stable"],"preview":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/%3Flanguage%3Den?vpw=1200&vph=1602&w=200&h=267","preview_tablet":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/%3Flanguage%3Den?vpw=800&vph=1068&w=200&h=267","preview_mobile":"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/spearhead/mobilebloglayout.wordpress.com/%3Flanguage%3Den?vpw=400&vph=534&w=200&h=267"}],"categories":[{"slug":"about","title":"About","description":"About","emoji":"👋","order":0},{"slug":"links","title":"Links","description":"Links","emoji":"🔗","order":1}]}
        """
        let remoteSiteDesignsWithoutBlogCategory = try! JSONDecoder().decode(
            RemoteSiteDesigns.self,
            from: remoteSiteDesignsWithoutBlogCategoryPayload.data(using: .utf8)!
        )

        // When
        let sections = SiteDesignSectionLoader.assembleSections(
            remoteDesigns: remoteSiteDesignsWithoutBlogCategory,
            vertical: nil
        )

        // Then
        XCTAssertEqual(sections.count, 1)

        let sectionOne = sections[0]
        XCTAssertEqual(sectionOne.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value)
    }

}
