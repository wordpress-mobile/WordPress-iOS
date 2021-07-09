import XCTest
@testable import WordPress

class GutenbergRefactoredGalleryUploadProcessorTests: XCTestCase {
    struct ImageUploadJob {
        let localId: Int32
        let remoteId: Int
        let localUrl: String
        let remoteURL: String
        let mediaLink: String
    }

    let oldPostContent = """
<!-- wp:gallery {"ids":[-708],"columns":1,"linkTo":"file"} -->
<figure class="wp-block-gallery columns-1 is-cropped">
    <ul class="blocks-gallery-grid">
        <li class="blocks-gallery-item">
            <figure>
                <a href="file:///usr/temp/image708.jpg">
                    <img src="file:///usr/temp/image708.jpg" data-id="-708" class="wp-image--708" data-full-url="file:///usr/temp/image708.jpg" data-link="https://files.wordpress.com/?p=-708"/>
                </a>
                <figcaption class="blocks-gallery-item__caption">
                    <p>Caption</p>
                </figcaption>
            </figure>
        </li>
    </ul>
</figure>
<!-- /wp:gallery -->
"""

    let oldPostResultContent = """
<!-- wp:gallery {"columns":1,"ids":[708],"linkTo":"file"} -->
<figure class="wp-block-gallery columns-1 is-cropped">
    <ul class="blocks-gallery-grid">
        <li class="blocks-gallery-item">
            <figure>
                <a href="https://files.wordpress.com/708.jpg" >
                    <img src="https://files.wordpress.com/708.jpg" data-id="708" class="wp-image-708" data-full-url="https://files.wordpress.com/708.jpg" data-link="https://files.wordpress.com/?p=708" />
                </a>
                <figcaption class="blocks-gallery-item__caption">
                    <p>Caption</p>
                </figcaption>
            </figure>
        </li>
    </ul>
</figure>
<!-- /wp:gallery -->
"""

    func imageBlockContent(localMediaId: Int32, localImageUrl: String) -> String {
        return """
    <!-- wp:image {"id":\(localMediaId)} -->
    <figure class="wp-block-image"><img src="\(localImageUrl)" alt="" class="wp-image-\(localMediaId)"/></figure>
    <!-- /wp:image -->
    """
    }

    func imageBlockResultContent(remoteMediaId: Int, remoteImageUrl: String) -> String {
        return """
    <!-- wp:image {"id":\(remoteMediaId)} -->
    <figure class="wp-block-image"><img src="\(remoteImageUrl)" alt="" class="wp-image-\(remoteMediaId)"/></figure>
    <!-- /wp:image -->
    """
    }

    func galleryBlock(innerBlocks: String, imageCount: Int) -> String {
        return """
    <!-- wp:gallery {"linkTo":"none","imageCount":\(imageCount)} -->
    <figure class="wp-block-gallery blocks-gallery-grid has-nested-images columns-\(imageCount) is-cropped">
    \(innerBlocks)</figure>
    <!-- /wp:gallery -->
    """
    }

    func testRefactoredGalleryImageBlockProcessor() {
        let job = ImageUploadJob(localId: -123456789, remoteId: 123456789, localUrl: "file:///usr/temp/123.jpg", remoteURL: "https://files.wordpress.com/123.jpg", mediaLink: "https://files.wordpress.com/?p=123")

        let gutenbergImgPostUploadProcessor = GutenbergImgUploadProcessor(mediaUploadID: job.localId, serverMediaID: job.remoteId, remoteURLString: job.remoteURL)

        let image = imageBlockContent(localMediaId: job.localId, localImageUrl: job.localUrl)
        let refactoredGalleryContent = galleryBlock(innerBlocks: image, imageCount: 1)
        let resultContent = gutenbergImgPostUploadProcessor.process(refactoredGalleryContent)
        let imageResult = imageBlockResultContent(remoteMediaId: job.remoteId, remoteImageUrl: job.remoteURL)

        let refactoredGalleryResultContent = galleryBlock(innerBlocks: imageResult, imageCount: 1)

        XCTAssertEqual(resultContent, refactoredGalleryResultContent, "Post content should be updated correctly")
    }

    func testRefactoredGalleryBlockProcessor() {
        let mediaJobs = [
            ImageUploadJob(localId: -1, remoteId: 1, localUrl: "file:///usr/temp/1.jpg", remoteURL: "https://files.wordpress.com/1.jpg", mediaLink: "https://files.wordpress.com/?p=1"),
            ImageUploadJob(localId: -2, remoteId: 2, localUrl: "file:///usr/temp/2.jpg", remoteURL: "https://files.wordpress.com/2.jpg", mediaLink: "https://files.wordpress.com/?p=2"),
            ImageUploadJob(localId: -3, remoteId: 3, localUrl: "file:///usr/temp/3.jpg", remoteURL: "https://files.wordpress.com/3.jpg", mediaLink: "https://files.wordpress.com/?p=3")
        ]

        var galleryInnerBlocks = ""
        var galleryResultInnerBlocks = ""
        for job in mediaJobs {
            galleryInnerBlocks += imageBlockContent(localMediaId: job.localId, localImageUrl: job.localUrl) + "\n"
            galleryResultInnerBlocks += imageBlockResultContent(remoteMediaId: job.remoteId, remoteImageUrl: job.remoteURL) + "\n"
        }
        let galleryBlockContent = galleryBlock(innerBlocks: galleryInnerBlocks, imageCount: mediaJobs.count)
        let galleryResultBlockContent = galleryBlock(innerBlocks: galleryResultInnerBlocks, imageCount: mediaJobs.count)

        var resultContent = galleryBlockContent

        resultContent = mediaJobs.reduce(into: resultContent) { (content, mediaJob) in
            let gallerydProcessor = GutenbergGalleryUploadProcessor(mediaUploadID: mediaJob.localId, serverMediaID: mediaJob.remoteId, remoteURLString: mediaJob.remoteURL, mediaLink: mediaJob.mediaLink)
            let imageProcessor = GutenbergImgUploadProcessor(mediaUploadID: mediaJob.localId, serverMediaID: mediaJob.remoteId, remoteURLString: mediaJob.remoteURL)
            content = gallerydProcessor.process(content)
            content = imageProcessor.process(content)
        }

        XCTAssertEqual(resultContent, galleryResultBlockContent, "Post content should be updated correctly")
    }

    func testMixedOldRefactoredGalleryBlockProcessor() {
        let mediaJobs = [
            ImageUploadJob(localId: -708, remoteId: 708, localUrl: "file:///usr/temp/image708.jpg", remoteURL: "https://files.wordpress.com/708.jpg", mediaLink: "https://files.wordpress.com/?p=708"),
            ImageUploadJob(localId: -1, remoteId: 1, localUrl: "file:///usr/temp/1.jpg", remoteURL: "https://files.wordpress.com/1.jpg", mediaLink: "https://files.wordpress.com/?p=1")
        ]
        let job = mediaJobs[1]
        let galleryInnerBlocks = imageBlockContent(localMediaId: job.localId, localImageUrl: job.localUrl) + "\n"
        let galleryResultInnerBlocks = imageBlockResultContent(remoteMediaId: job.remoteId, remoteImageUrl: job.remoteURL) + "\n"
        let galleryBlockContent = galleryBlock(innerBlocks: galleryInnerBlocks, imageCount: mediaJobs.count)
        let galleryResultBlockContent = galleryBlock(innerBlocks: galleryResultInnerBlocks, imageCount: mediaJobs.count)
        let postResultContent = oldPostResultContent + "\n" + galleryResultBlockContent
        var resultContent = oldPostContent + "\n" + galleryBlockContent

        resultContent = mediaJobs.reduce(into: resultContent) { (content, mediaJob) in
            let gallerydProcessor = GutenbergGalleryUploadProcessor(mediaUploadID: mediaJob.localId, serverMediaID: mediaJob.remoteId, remoteURLString: mediaJob.remoteURL, mediaLink: mediaJob.mediaLink)
            let imageProcessor = GutenbergImgUploadProcessor(mediaUploadID: mediaJob.localId, serverMediaID: mediaJob.remoteId, remoteURLString: mediaJob.remoteURL)
            content = gallerydProcessor.process(content)
            content = imageProcessor.process(content)
        }

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }
}
