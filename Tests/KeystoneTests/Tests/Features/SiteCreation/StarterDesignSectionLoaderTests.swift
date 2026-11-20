import Foundation
import Testing
import WordPressKit

@testable import WordPress

struct StarterDesignSectionLoaderTests {
    private let designs = [
        makeDesign("formwork", tier: "premium", categories: ["blog", "magazine"]),
        makeDesign("ury", tier: "free", categories: ["blog", "art-design"]),
        makeDesign("golazo", tier: "personal", categories: ["blog", "sports-fitness"]),
        makeDesign("archivist", tier: "free", categories: ["about", "blog"]),
        makeDesign("creatio-2", tier: "free", categories: ["link-in-bio"], isVirtual: true)
    ]

    @Test func offersOnlyFreeNonVirtualDesigns() {
        let sections = StarterDesignSectionLoader.sections(from: designs, siteTitle: nil, language: "en")

        let slugs = Set(sections.flatMap { $0.designs.map(\.slug) })
        #expect(slugs == ["ury", "archivist"])
    }

    @Test func sectionsFollowCatalogCategoryOrder() {
        let sections = StarterDesignSectionLoader.sections(from: designs, siteTitle: nil, language: "en")

        #expect(sections.map(\.categorySlug) == ["blog", "art-design", "about"])
        #expect(sections.map(\.title) == ["BLOG", "ART-DESIGN", "ABOUT"])
        #expect(sections.first?.designs.map(\.slug) == ["ury", "archivist"])
        #expect(sections.allSatisfy { $0.sectionType == .standard && $0.hasLandscapeThumbnails })
    }

    @Test func mapsDesignToThemeAndScreenshot() throws {
        let design = StarterDesignSectionLoader.siteDesign(from: designs[1], siteTitle: "My Site", language: "fr")

        #expect(design.slug == "ury")
        #expect(design.themeSlug == "ury")
        #expect(design.screenshot == "https://example.com/ury.png")
        #expect(design.mobileScreenshot == design.screenshot)
        #expect(design.tabletScreenshot == design.screenshot)
    }

    @Test func previewUsesStylesheetLanguageAndSiteTitle() throws {
        let url = try #require(
            URLComponents(
                string: StarterDesignSectionLoader.previewURL(for: designs[1], siteTitle: "My (Site)", language: "fr")
            )
        )

        #expect(url.host == "public-api.wordpress.com")
        #expect(url.path == "/wpcom/v2/block-previews/site")
        #expect(url.queryItems?.first { $0.name == "stylesheet" }?.value == "pub/ury")
        #expect(url.queryItems?.first { $0.name == "language" }?.value == "fr")
        #expect(url.queryItems?.first { $0.name == "site_title" }?.value == "My (Site)")
    }

    @Test(arguments: [nil, ""])
    func previewFallsBackToDesignTitle(siteTitle: String?) throws {
        let url = try #require(
            URLComponents(
                string: StarterDesignSectionLoader.previewURL(for: designs[1], siteTitle: siteTitle, language: "en")
            )
        )

        #expect(url.queryItems?.first { $0.name == "site_title" }?.value == "URY")
    }
}

private func makeDesign(_ slug: String, tier: String, categories: [String], isVirtual: Bool = false) -> StarterDesign {
    StarterDesign(
        slug: slug,
        title: slug.uppercased(),
        stylesheet: "pub/\(slug)",
        categories: categories.map { StarterDesign.Category(slug: $0, name: $0.uppercased()) },
        themeTier: tier,
        screenshot: "https://example.com/\(slug).png",
        isVirtual: isVirtual
    )
}
