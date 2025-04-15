import XCTest
import Gutenberg
@testable import WordPress

final class GutenbergFilesAppMediaSourceTests: XCTestCase {
    func testThatImageFiltersAreApplied() {
        // Given
        let filters: [Gutenberg.MediaType] = [.image]
        let allowedTypes = [
            "public.jpeg",
            "public.mpeg-4",
            "com.compuserve.gif",
            "com.microsoft.excel.xls",
            "com.adobe.pdf"
        ]

        // When
        let documentTypes = GutenbergFilesAppMediaSource.getDocumentTypes(filters: filters, allowedTypesOnBlog: allowedTypes)

        // Then only images are allowed
        XCTAssertEqual(Set(documentTypes), Set([
            "public.jpeg",
            "com.compuserve.gif"
        ]))
    }

    func testThatVideoAndImageFiltersAreApplied() {
        // Given
        let filters: [Gutenberg.MediaType] = [.image, .video]
        let allowedTypes = [
            "public.jpeg",
            "public.mpeg-4",
            "com.compuserve.gif",
            "com.microsoft.excel.xls",
            "com.adobe.pdf"
        ]

        // When
        let documentTypes = GutenbergFilesAppMediaSource.getDocumentTypes(filters: filters, allowedTypesOnBlog: allowedTypes)

        // Then both images and videos are allowed
        XCTAssertEqual(Set(documentTypes), Set([
            "public.jpeg",
            "public.mpeg-4",
            "com.compuserve.gif"
        ]))
    }

    func testThatAllTypesAreAllowedWhenFiltersContainAny() {
        // Given
        let filters: [Gutenberg.MediaType] = [.any]
        let allowedTypes = [
            "public.jpeg",
            "public.mpeg-4",
            "com.compuserve.gif",
            "com.microsoft.excel.xls",
            "com.adobe.pdf"
        ]

        // When
        let documentTypes = GutenbergFilesAppMediaSource.getDocumentTypes(filters: filters, allowedTypesOnBlog: allowedTypes)

        // Then all types are allowed
        XCTAssertEqual(Set(documentTypes), Set([
            "public.jpeg",
            "public.mpeg-4",
            "com.compuserve.gif",
            "com.microsoft.excel.xls",
            "com.adobe.pdf"
        ]))
    }
}
