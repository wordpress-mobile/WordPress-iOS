import UIKit
import XCTest
import WordPressKit
@testable import WordPress

class SiteDesignSectionLoaderTests: XCTestCase {
    /// The thumbnail sizes follow the horizontal size class of the window that displays them.
    private let windowSizeClass = UIUserInterfaceSizeClass.compact

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
        let section = SiteDesignSectionLoader.getRecommendedSectionForVertical(
            validVertical,
            remoteDesigns: remoteDesigns,
            windowSizeClass: windowSizeClass
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
        let section = SiteDesignSectionLoader.getRecommendedSectionForVertical(
            invalidVertical,
            remoteDesigns: remoteDesigns,
            windowSizeClass: windowSizeClass
        )

        // Then
        XCTAssertNil(section)
    }

    func testCategorySectionsForRemoteSiteSiteDesigns() throws {
        // When
        let sections = SiteDesignSectionLoader.getCategorySectionsForRemoteSiteDesigns(
            remoteDesigns,
            windowSizeClass: windowSizeClass
        )

        // Then
        // The Slugs category has no designs so it isn't returned
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].categorySlug, "about")
        XCTAssertEqual(sections[1].categorySlug, "blog")
    }

    /// Tests entire assembly of sections when a recommended vertical is used
    func testAssembleSections() throws {
        // Given
        let testVertical = SiteIntentVertical(slug: "test-vertical", localizedTitle: "Testing", emoji: "")
        let categorySections = SiteDesignSectionLoader.getCategorySectionsForRemoteSiteDesigns(
            remoteDesigns,
            windowSizeClass: windowSizeClass
        )

        // When
        let sections = SiteDesignSectionLoader.assembleSections(
            categorySections: categorySections,
            remoteDesigns: remoteDesigns,
            vertical: testVertical,
            windowSizeClass: windowSizeClass
        )

        // Then
        XCTAssertEqual(sections.count, 3)

        let recommendedSection = sections[0]
        XCTAssertEqual(recommendedSection.title, "Best for Testing")
        XCTAssertEqual(recommendedSection.categorySlug, "recommended_test-vertical")
        XCTAssertEqual(
            recommendedSection.thumbnailSize,
            SiteDesignCategoryThumbnailSize.recommended.value(for: windowSizeClass)
        )

        let sectionOne = sections[1]
        XCTAssertEqual(sectionOne.categorySlug, "about")
        XCTAssertEqual(sectionOne.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value(for: windowSizeClass))

        let sectionTwo = sections[2]
        XCTAssertEqual(sectionTwo.categorySlug, "blog")
        XCTAssertEqual(sectionTwo.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value(for: windowSizeClass))
    }

    /// Tests that sections built for one size class are laid out at the sizes for another, in the same order
    func testAssembleSectionsForAnotherSizeClass() throws {
        // Given
        let testVertical = SiteIntentVertical(slug: "test-vertical", localizedTitle: "Testing", emoji: "")
        let categorySections = SiteDesignSectionLoader.getCategorySectionsForRemoteSiteDesigns(
            remoteDesigns,
            windowSizeClass: windowSizeClass
        )
        let regularWindowSizeClass = UIUserInterfaceSizeClass.regular

        // When
        let sections = SiteDesignSectionLoader.assembleSections(
            categorySections: categorySections,
            remoteDesigns: remoteDesigns,
            vertical: testVertical,
            windowSizeClass: regularWindowSizeClass
        )

        // Then
        XCTAssertNotEqual(
            SiteDesignCategoryThumbnailSize.category.value(for: windowSizeClass),
            SiteDesignCategoryThumbnailSize.category.value(for: regularWindowSizeClass)
        )
        XCTAssertEqual(sections.map(\.categorySlug), ["recommended_test-vertical", "about", "blog"])
        XCTAssertEqual(
            sections[0].thumbnailSize,
            SiteDesignCategoryThumbnailSize.recommended.value(for: regularWindowSizeClass)
        )
        for (section, categorySection) in zip(sections.dropFirst(), categorySections) {
            XCTAssertEqual(
                section.thumbnailSize,
                SiteDesignCategoryThumbnailSize.category.value(for: regularWindowSizeClass)
            )
            XCTAssertEqual(section.designs.map(\.slug), categorySection.designs.map(\.slug))
        }
    }

    /// Tests entire assembly of sections when there are no matches for a vertical and we fall back to the "Blog" category
    func testAssembleSectionsFallback() throws {
        // Given
        let categorySections = SiteDesignSectionLoader.getCategorySectionsForRemoteSiteDesigns(
            remoteDesigns,
            windowSizeClass: windowSizeClass
        )

        // When
        let sections = SiteDesignSectionLoader.assembleSections(
            categorySections: categorySections,
            remoteDesigns: remoteDesigns,
            vertical: nil,
            windowSizeClass: windowSizeClass
        )

        // Then
        XCTAssertEqual(sections.count, 2)

        let recommendedSection = sections[0]
        XCTAssertEqual(recommendedSection.title, "Best for Blogging")
        XCTAssertEqual(recommendedSection.categorySlug, "blog")
        XCTAssertEqual(
            recommendedSection.thumbnailSize,
            SiteDesignCategoryThumbnailSize.recommended.value(for: windowSizeClass)
        )

        let sectionOne = sections[1]
        XCTAssertEqual(sectionOne.categorySlug, "about")
        XCTAssertEqual(sectionOne.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value(for: windowSizeClass))
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
        let categorySections = SiteDesignSectionLoader.getCategorySectionsForRemoteSiteDesigns(
            remoteSiteDesignsWithoutBlogCategory,
            windowSizeClass: windowSizeClass
        )

        // When
        let sections = SiteDesignSectionLoader.assembleSections(
            categorySections: categorySections,
            remoteDesigns: remoteSiteDesignsWithoutBlogCategory,
            vertical: nil,
            windowSizeClass: windowSizeClass
        )

        // Then
        XCTAssertEqual(sections.count, 1)

        let sectionOne = sections[0]
        XCTAssertEqual(sectionOne.thumbnailSize, SiteDesignCategoryThumbnailSize.category.value(for: windowSizeClass))
    }
}
