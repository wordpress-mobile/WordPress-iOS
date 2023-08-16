import Foundation
import OHHTTPStubs
import XCTest
@testable import WordPress

final class ItemProviderMediaExporterTests: XCTestCase {

    func testWebPSupport() throws {
        // GIVEN a provider with a WebP image
        let imageURL = try XCTUnwrap(Bundle.test.url(forResource: "test-webp", withExtension: "webp"))
        let provider = NSItemProvider()
        provider.registerFileRepresentation(forTypeIdentifier: UTType.webP.identifier, visibility: .all) { completion in
            completion(imageURL, false, nil)
            return nil
        }

        // WHEN
        let exporter = ItemProviderMediaExporter(provider: provider)
        exporter.mediaDirectoryType = .temporary

        let media = try exportedMedia(from: exporter)

        // THEN it switched to heic from webp
        XCTAssertEqual(media.url.pathExtension, "heic")
        XCTAssertEqual(media.width, 1024.0)
        XCTAssertEqual(media.height, 772.0)
        XCTAssertNotNil(UIImage(data: try Data(contentsOf: media.url)))
    }

    func testThatGPSInformationIsRemoved() {

    }

    func exportedMedia(from exporter: ItemProviderMediaExporter) throws -> MediaExport {
        let expectation = self.expectation(description: "mediaExported")
        var result: Result<MediaExport, Error>?
        _ = exporter.export(onCompletion: { media in
            result = .success(media)
            expectation.fulfill()
        }, onError: { error in
            result = .failure(error)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 2)
        return try XCTUnwrap(result).get()
    }
}
