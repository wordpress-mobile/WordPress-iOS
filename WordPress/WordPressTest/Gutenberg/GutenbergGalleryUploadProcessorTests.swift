import XCTest
@testable import WordPress

class GutenbergGalleryUploadProcessorTests: XCTestCase {

    let postContent = """
<!-- wp:gallery {"ids":["-708","-415","-701"],"columns":3,"linkTo":"media"} -->
<figure class="wp-block-gallery columns-3 is-cropped">
    <ul class="blocks-gallery-grid">
        <li class="blocks-gallery-item">
            <figure>
                <a href="file:///usr/temp/image708.jpg">
                    <img src="file:///usr/temp/image708.jpg" data-id="-708" class="wp-image--708" />
                </a>
                <figcaption class="blocks-gallery-item__caption">
                    <p>Caption</p>
                </figcaption>
            </figure>
        </li>
        <li class="blocks-gallery-item">
            <figure>
                <a href="file:///usr/temp/image415.jpg">
                    <img src="file:///usr/temp/image415.jpg" data-id="-415" class="wp-image--415" />
                </a>
                <figcaption class="blocks-gallery-item__caption">Alşksdf şlkas dolaş dfasd şad fsa
                    <br>Asf fasd fas
                    <br>A sdfasdf sadf
                    <br> Asdf</figcaption>
            </figure>
        </li>
        <li class="blocks-gallery-item">
            <figure>
                <a href="file:///usr/temp/image701.jpg">
                    <img src="file:///usr/temp/image701.jpg" data-id="-701" class="wp-image--701" />
                </a>
                <figcaption class="blocks-gallery-item__caption">Hello
                    <br>World
                </figcaption>
            </figure>
        </li>
    </ul>
</figure>
<!-- /wp:gallery -->
"""

    let postResultContent = """
<!-- wp:gallery {"columns":3,"ids":["708","415","701"],"linkTo":"media"} -->
<figure class="wp-block-gallery columns-3 is-cropped">
    <ul class="blocks-gallery-grid">
        <li class="blocks-gallery-item">
            <figure>
                <a href="https://files.wordpress.com/708.jpg" >
                    <img src="https://files.wordpress.com/708.jpg" data-id="708" class="wp-image-708" data-full-url="https://files.wordpress.com/708.jpg" />
                </a>
                <figcaption class="blocks-gallery-item__caption">
                    <p>Caption</p>
                </figcaption>
            </figure>
        </li>
        <li class="blocks-gallery-item">
            <figure>
                <a href="https://files.wordpress.com/415.jpg" >
                    <img src="https://files.wordpress.com/415.jpg" data-id="415" class="wp-image-415" data-full-url="https://files.wordpress.com/415.jpg" />
                </a>
                <figcaption class="blocks-gallery-item__caption">Alşksdf şlkas dolaş dfasd şad fsa
                    <br>Asf fasd fas
                    <br>A sdfasdf sadf
                    <br> Asdf</figcaption>
            </figure>
        </li>
        <li class="blocks-gallery-item">
            <figure>
                <a href="https://files.wordpress.com/701.jpg" >
                    <img src="https://files.wordpress.com/701.jpg" data-id="701" class="wp-image-701" data-full-url="https://files.wordpress.com/701.jpg" />
                </a>
                <figcaption class="blocks-gallery-item__caption">Hello
                    <br>World
                </figcaption>
            </figure>
        </li>
    </ul>
</figure>
<!-- /wp:gallery -->
"""

    struct ImageUploadJob {
        let uploadID: Int
        let serverID: Int
        let serverURL: String
    }

    func testGutenbergGalleryBlockProcessor() {
        let mediaJobs = [
            ImageUploadJob(uploadID: -708, serverID: 708, serverURL: "https://files.wordpress.com/708.jpg"),
            ImageUploadJob(uploadID: -415, serverID: 415, serverURL: "https://files.wordpress.com/415.jpg"),
            ImageUploadJob(uploadID: -701, serverID: 701, serverURL: "https://files.wordpress.com/701.jpg"),
        ]

        var resultContent = postContent

        resultContent = mediaJobs.reduce(into: resultContent) { (content, mediaJob) in
            let processor = GutenbergGalleryUploadProcessor(mediaUploadID: mediaJob.uploadID, serverMediaID: mediaJob.serverID, remoteURLString: mediaJob.serverURL)
            content = processor.process(content)
        }

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

}
