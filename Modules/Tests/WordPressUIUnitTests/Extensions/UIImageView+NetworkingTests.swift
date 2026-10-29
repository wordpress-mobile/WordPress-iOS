import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing
import UIKit
import WordPressSharedUI
import WordPressUI

@MainActor
@Suite(.serialized)
struct UIImageViewNetworkingTests {
    @Test func loadsImage() async {
        let url = FakeImageServer.url("/image.png")

        let result = await download(url)

        #expect(result == .success)
        #expect(ImageCache.shared.getImage(forKey: url.absoluteString) != nil)
    }

    /// `*.files.wordpress.com` images redirect to `/wp-content/uploads` on the site's own domain.
    @Test func loadsRedirectedImage() async {
        let url = FakeImageServer.url("/redirect.png")

        let result = await download(url)

        #expect(result == .success)
        #expect(ImageCache.shared.getImage(forKey: url.absoluteString) != nil)
    }

    @Test func rejectsMShotsPlaceholder() async {
        let url = FakeImageServer.url("/mshots/v1/example.com")

        let result = await download(url)

        #expect(result == .mShotsPlaceholder)
        #expect(ImageCache.shared.getImage(forKey: url.absoluteString) == nil)
    }

    private enum Outcome: Equatable {
        case success
        case mShotsPlaceholder
        case otherFailure
    }

    private func download(_ url: URL) async -> Outcome {
        let fakeServer = FakeImageServer.install()
        defer { HTTPStubs.removeStub(fakeServer) }

        let imageView = UIImageView()
        return await withCheckedContinuation { continuation in
            imageView.downloadImage(
                from: url,
                success: { _ in continuation.resume(returning: .success) },
                failure: { error in
                    if case .mShotsPlaceholder = error as? UIImageView.ImageDownloadError {
                        continuation.resume(returning: .mShotsPlaceholder)
                    } else {
                        continuation.resume(returning: .otherFailure)
                    }
                }
            )
        }
    }
}

/// Serves a PNG for any path, except:
/// - `/redirect.png` answers 301 to `/redirected.png`.
/// - `/mshots/v1/<anything but default>` answers 307 to `/mshots/v1/default`, as mShots does while it
///   generates a screenshot.
private enum FakeImageServer {
    private static let host = "fake-image-server.test"

    private static let png = UIImage(color: .red, size: CGSize(width: 4, height: 4)).pngData()!

    /// A unique URL per download, so that a repeated run does not hit an image cached by an earlier run.
    static func url(_ path: String) -> URL {
        URL(string: "https://\(host)\(path)?test=\(UUID().uuidString)")!
    }

    static func install() -> HTTPStubsDescriptor {
        stub(condition: isHost(host)) { request in
            switch request.url?.path {
            case "/redirect.png":
                return redirect(to: "/redirected.png", statusCode: 301)
            case let path? where path.hasPrefix("/mshots/v1/") && path != "/mshots/v1/default":
                return redirect(to: "/mshots/v1/default", statusCode: 307)
            default:
                return HTTPStubsResponse(data: png, statusCode: 200, headers: ["Content-Type": "image/png"])
            }
        }
    }

    private static func redirect(to path: String, statusCode: Int32) -> HTTPStubsResponse {
        HTTPStubsResponse(data: Data(), statusCode: statusCode, headers: ["Location": "https://\(host)\(path)"])
    }
}
