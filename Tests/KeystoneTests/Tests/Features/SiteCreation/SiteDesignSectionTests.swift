import Testing
import UIKit
@testable import WordPress

struct SiteDesignSectionTests {
    @Test(arguments: [
        (SiteDesignSectionType.recommended, UIUserInterfaceSizeClass.compact, CGSize(width: 350, height: 450)),
        (.recommended, .regular, CGSize(width: 327, height: 450)),
        (.standard, .compact, CGSize(width: 200, height: 260)),
        (.standard, .regular, CGSize(width: 250, height: 325))
    ])
    func thumbnailSizeFollowsTheWindowSizeClass(
        sectionType: SiteDesignSectionType,
        windowSizeClass: UIUserInterfaceSizeClass,
        expectedSize: CGSize
    ) {
        var section = SiteDesignSection(designs: [], categorySlug: "blog", title: "Blog", sectionType: sectionType)
        section.windowSizeClass = windowSizeClass

        #expect(section.thumbnailSize == expectedSize)
    }

    /// The previews are requested once, so they must be large enough for every thumbnail size.
    @Test func previewSizeIsTheLargestThumbnailSize() {
        let thumbnailSizes = [SiteDesignCategoryThumbnailSize.recommended, .category]
            .flatMap { thumbnailSize in
                [UIUserInterfaceSizeClass.compact, .regular].map { thumbnailSize.value(for: $0) }
            }
        let previewSize = SiteDesignCategoryThumbnailSize.previewSize

        #expect(thumbnailSizes.allSatisfy { $0.width <= previewSize.width && $0.height <= previewSize.height })
        #expect(thumbnailSizes.contains(previewSize))
    }
}
