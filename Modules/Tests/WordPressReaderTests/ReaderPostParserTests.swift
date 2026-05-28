import Testing
import Foundation
@testable import WordPressReader

@Suite
struct ReaderPostParserTests {

    // MARK: - Gutenberg Gallery (wp-block-gallery)

    @Test func parseWPBlockGalleryWithThreeImages() {
        let html = """
        <figure class="wp-block-gallery has-nested-images columns-3 is-cropped wp-block-gallery-1 is-layout-flex wp-block-gallery-is-layout-flex">
            <figure class="wp-block-image size-large">
                <img decoding="async" width="1024" height="768"
                     data-id="2001"
                     src="https://example.com/wp-content/uploads/photo1.jpg?w=1024"
                     alt="Sunset over mountains"
                     class="wp-image-2001"
                     data-orig-file="https://example.com/wp-content/uploads/photo1.jpg"
                     data-orig-size="4032,3024"
                     srcset="https://example.com/wp-content/uploads/photo1.jpg?w=1024 1024w, https://example.com/wp-content/uploads/photo1.jpg?w=150 150w, https://example.com/wp-content/uploads/photo1.jpg?w=300 300w, https://example.com/wp-content/uploads/photo1.jpg?w=768 768w"
                     data-image-description="<p>A beautiful sunset</p>"
                     data-image-caption="<p>Sunset caption</p>" />
            </figure>
            <figure class="wp-block-image size-large">
                <img decoding="async" width="1024" height="768"
                     data-id="2002"
                     src="https://example.com/wp-content/uploads/photo2.jpg?w=1024"
                     alt="Forest trail"
                     class="wp-image-2002"
                     data-orig-file="https://example.com/wp-content/uploads/photo2.jpg"
                     data-orig-size="3000,2000"
                     srcset="https://example.com/wp-content/uploads/photo2.jpg?w=1024 1024w, https://example.com/wp-content/uploads/photo2.jpg?w=300 300w"
                     data-image-description=""
                     data-image-caption="" />
            </figure>
            <figure class="wp-block-image size-large">
                <img decoding="async" width="768" height="1024"
                     data-id="2003"
                     src="https://example.com/wp-content/uploads/photo3.jpg?w=768"
                     alt=""
                     class="wp-image-2003"
                     data-orig-file="https://example.com/wp-content/uploads/photo3.jpg"
                     data-orig-size="3024,4032" />
            </figure>
        </figure>
        """

        let elements = ReaderPostParser.parse(html)
        #expect(elements.count == 1)

        guard case .gallery(let gallery) = elements.first else {
            Issue.record("Expected gallery element")
            return
        }

        #expect(gallery.images.count == 3)

        // First image
        let first = gallery.images[0]
        #expect(first.src.absoluteString == "https://example.com/wp-content/uploads/photo1.jpg?w=1024")
        #expect(first.originalFileURL?.absoluteString == "https://example.com/wp-content/uploads/photo1.jpg")
        #expect(first.originalSize == CGSize(width: 4032, height: 3024))
        #expect(first.srcset.count == 4)
        #expect(first.srcset[0].width == 1024)
        #expect(first.srcset[1].width == 150)
        #expect(first.description == "A beautiful sunset")
        #expect(first.caption == "Sunset caption")

        // Second image
        let second = gallery.images[1]
        #expect(second.src.absoluteString == "https://example.com/wp-content/uploads/photo2.jpg?w=1024")
        #expect(second.originalSize == CGSize(width: 3000, height: 2000))
        #expect(second.srcset.count == 2)
        #expect(second.description == nil)
        #expect(second.caption == nil)

        // Third image - no srcset, no description/caption
        let third = gallery.images[2]
        #expect(third.src.absoluteString == "https://example.com/wp-content/uploads/photo3.jpg?w=768")
        #expect(third.originalSize == CGSize(width: 3024, height: 4032))
        #expect(third.srcset.isEmpty)
        #expect(third.description == nil)
        #expect(third.caption == nil)
    }

    // MARK: - Jetpack Tiled Gallery (block)

    @Test func parseJetpackTiledGalleryBlock() {
        let html = """
        <figure class="wp-block-jetpack-tiled-gallery">
            <div class="tiled-gallery__gallery">
                <div class="tiled-gallery__row">
                    <img src="https://example.com/photo-a.jpg"
                         data-orig-file="https://example.com/photo-a-full.jpg"
                         data-orig-size="2000,1500" />
                    <img src="https://example.com/photo-b.jpg"
                         data-orig-file="https://example.com/photo-b-full.jpg"
                         data-orig-size="1800,1200" />
                </div>
            </div>
        </figure>
        """

        let elements = ReaderPostParser.parse(html)
        #expect(elements.count == 1)

        guard case .gallery(let gallery) = elements.first else {
            Issue.record("Expected gallery element")
            return
        }
        #expect(gallery.images.count == 2)
        #expect(gallery.images[0].src.absoluteString == "https://example.com/photo-a.jpg")
        #expect(gallery.images[1].src.absoluteString == "https://example.com/photo-b.jpg")
    }

    // MARK: - Jetpack Tiled Gallery (classic)

    @Test func parseJetpackTiledGalleryClassic() {
        let html = """
        <div class="tiled-gallery type-rectangular">
            <div class="gallery-row">
                <div class="gallery-group">
                    <img src="https://example.com/classic1.jpg"
                         data-orig-file="https://example.com/classic1-full.jpg" />
                </div>
                <div class="gallery-group">
                    <img src="https://example.com/classic2.jpg" />
                </div>
            </div>
        </div>
        """

        let elements = ReaderPostParser.parse(html)
        #expect(elements.count == 1)

        guard case .gallery(let gallery) = elements.first else {
            Issue.record("Expected gallery element")
            return
        }
        #expect(gallery.images.count == 2)
        #expect(gallery.images[0].originalFileURL?.absoluteString == "https://example.com/classic1-full.jpg")
        #expect(gallery.images[1].originalFileURL == nil)
    }

    // MARK: - Classic Gallery Shortcode

    @Test func parseClassicGalleryShortcode() {
        let html = """
        <div class="gallery gallery-columns-3">
            <figure class="gallery-item">
                <div class="gallery-icon landscape">
                    <img src="https://example.com/shortcode1.jpg"
                         data-orig-size="800,600" />
                </div>
            </figure>
            <figure class="gallery-item">
                <div class="gallery-icon portrait">
                    <img src="https://example.com/shortcode2.jpg"
                         data-orig-size="600,800" />
                </div>
            </figure>
        </div>
        """

        let elements = ReaderPostParser.parse(html)
        #expect(elements.count == 1)

        guard case .gallery(let gallery) = elements.first else {
            Issue.record("Expected gallery element")
            return
        }
        #expect(gallery.images.count == 2)
        #expect(gallery.images[0].originalSize == CGSize(width: 800, height: 600))
        #expect(gallery.images[1].originalSize == CGSize(width: 600, height: 800))
    }

    // MARK: - No galleries

    @Test func parseHTMLWithNoGalleries() {
        let html = """
        <p>Just a regular paragraph with an <img src="https://example.com/single.jpg" /> image.</p>
        """

        let elements = ReaderPostParser.parse(html)
        #expect(elements.isEmpty)
    }

    // MARK: - Multiple galleries

    @Test func parseMultipleGalleries() throws {
        let html = """
        <p>Some text</p>
        <figure class="wp-block-gallery">
            <figure class="wp-block-image">
                <img src="https://example.com/gallery1-img1.jpg" />
            </figure>
        </figure>
        <p>More text</p>
        <figure class="wp-block-gallery">
            <figure class="wp-block-image">
                <img src="https://example.com/gallery2-img1.jpg" />
            </figure>
            <figure class="wp-block-image">
                <img src="https://example.com/gallery2-img2.jpg" />
            </figure>
        </figure>
        """

        let elements = ReaderPostParser.parse(html)
        try #require(elements.count == 2)

        guard case .gallery(let gallery1) = elements[0],
              case .gallery(let gallery2) = elements[1] else {
            Issue.record("Expected gallery elements")
            return
        }
        #expect(gallery1.images.count == 1)
        #expect(gallery2.images.count == 2)
    }

    // MARK: - Srcset edge cases

    @Test func parseSrcsetWithSingleEntry() {
        let html = """
        <figure class="wp-block-gallery">
            <figure class="wp-block-image">
                <img src="https://example.com/photo.jpg"
                     srcset="https://example.com/photo.jpg?w=800 800w" />
            </figure>
        </figure>
        """

        let elements = ReaderPostParser.parse(html)
        guard case .gallery(let gallery) = elements.first else {
            Issue.record("Expected gallery")
            return
        }
        #expect(gallery.images[0].srcset.count == 1)
        #expect(gallery.images[0].srcset[0].width == 800)
    }

    // MARK: - Malformed HTML

    @Test func parseMalformedHTML() {
        let html = "<div class=\"gallery\"><img src=\"https://example.com/a.jpg\"><p>unclosed tags"

        let elements = ReaderPostParser.parse(html)
        #expect(elements.count == 1)
        guard case .gallery(let gallery) = elements.first else {
            Issue.record("Expected gallery")
            return
        }
        #expect(gallery.images.count == 1)
    }

    @Test func parseEmptyHTML() {
        let elements = ReaderPostParser.parse("")
        #expect(elements.isEmpty)
    }

    @Test func parseGalleryWithNoImages() {
        let html = "<figure class=\"wp-block-gallery\"><p>No images here</p></figure>"
        let elements = ReaderPostParser.parse(html)
        #expect(elements.isEmpty)
    }

    @Test func parseImageWithMissingSrc() {
        let html = """
        <figure class="wp-block-gallery">
            <figure class="wp-block-image">
                <img data-orig-file="https://example.com/photo.jpg" />
            </figure>
        </figure>
        """
        let elements = ReaderPostParser.parse(html)
        #expect(elements.isEmpty)
    }
}
