import UIKit
import ImageIO
import UniformTypeIdentifiers
import Gifu
import Testing
@testable import AsyncImageKit

@MainActor
@Suite struct AsyncImageViewTests {
    // MARK: - GIFImageView

    @Test func resetClearsPlayingGIF() async throws {
        let (gifView, window) = try await makePlayingGIFView()
        defer { window.isHidden = true }

        gifView.reset()
        try await renderFrames(of: gifView)

        #expect(!gifView.isAnimatingGIF)
        #expect(gifView.image == nil)
    }

    @Test func staticImageReplacesPlayingGIF() async throws {
        let (gifView, window) = try await makePlayingGIFView()
        defer { window.isHidden = true }

        let staticImage = Self.makeImage(color: .green)
        gifView.configure(image: staticImage)
        try await renderFrames(of: gifView)

        #expect(!gifView.isAnimatingGIF)
        #expect(gifView.image === staticImage)
    }

    // MARK: - Saliency

    @Test func portraitImageWithNoSalientRegionIsShownImmediately() async throws {
        let url = try #require(URL(string: "https://example.files.wordpress.com/tests/\(UUID().uuidString).png"))
        let portraitImage = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 16))
            .image { context in
                UIColor.gray.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 8, height: 16))
            }

        // GIVEN detection already ran for this image and found no salient region
        ImageSaliencyService.shared.storeResult(nil, for: url)

        // GIVEN the image is in the memory cache
        ImageDownloader.shared.setCachedImage(portraitImage, for: url)
        defer { ImageDownloader.shared.setCachedImage(nil, for: url) }

        // WHEN
        let view = AsyncImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.isSaliencyDetectionEnabled = true
        view.setImage(with: url)

        // THEN the image is shown straight away, without waiting for detection again
        let imageView = try #require(view.subviews.first { $0 is GIFImageView })
        #expect(view.image === portraitImage)
        #expect(!imageView.isHidden)
    }

    // MARK: - Helpers

    /// Returns a GIF view in a window that is playing an animated GIF and has shown at least one frame.
    private func makePlayingGIFView() async throws -> (GIFImageView, UIWindow) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.isHidden = false
        let gifView = GIFImageView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        window.addSubview(gifView)

        let gif = try #require(AnimatedImage(gifData: try Self.makeGIF(frames: 4)))
        gifView.configure(image: gif)

        // Wait until the GIF shows its first frame.
        let deadline = ContinuousClock.now + .seconds(5)
        while gifView.image == nil, ContinuousClock.now < deadline {
            gifView.layer.displayIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(gifView.isAnimatingGIF)
        try #require(gifView.image != nil)
        return (gifView, window)
    }

    @Test func earlierSaliencyDetectionDoesNotChangeNewImageCrop() async throws {
        // GIVEN two portrait images in the memory cache
        let urlA = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).png"))
        let urlB = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).png"))
        let imageB = Self.makeImage(color: .blue, size: CGSize(width: 8, height: 16))
        ImageDownloader.shared.setCachedImage(
            Self.makeImage(color: .red, size: CGSize(width: 8, height: 16)),
            for: urlA
        )
        ImageDownloader.shared.setCachedImage(imageB, for: urlB)
        defer {
            ImageDownloader.shared.setCachedImage(nil, for: urlA)
            ImageDownloader.shared.setCachedImage(nil, for: urlB)
        }
        let view = AsyncImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.isSaliencyDetectionEnabled = true
        let imageView = try #require(view.subviews.first { $0 is GIFImageView })

        // WHEN detection starts for image A, which will find a region at the bottom
        view.setImage(with: urlA)
        ImageSaliencyService.shared.storeResult(CGRect(x: 0, y: 0.9, width: 0.1, height: 0.1), for: urlA)

        // ... and the view moves on to image B, whose region is already known, before it finishes
        let rectB = CGRect(x: 0, y: 0, width: 1, height: 0.1)
        ImageSaliencyService.shared.storeResult(rectB, for: urlB)
        view.setImage(with: urlB)
        for _ in 0..<20 {
            try await Task.sleep(for: .milliseconds(10))
            view.layoutIfNeeded()
        }

        // THEN image B is cropped to its own region
        let expectedFrame = try #require(
            ImageSaliencyService.shared.adjustedFrame(saliencyRect: rectB, imageSize: imageB.size, in: view.bounds.size)
        )
        #expect(view.image === imageB)
        #expect(imageView.frame == expectedFrame)
    }

    /// Gives the GIF's display link time to deliver several frames, and renders them.
    private func renderFrames(of gifView: GIFImageView) async throws {
        for _ in 0..<30 {
            gifView.layer.displayIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    static func makeImage(color: UIColor, size: CGSize = CGSize(width: 8, height: 8)) -> UIImage {
        UIGraphicsImageRenderer(size: size)
            .image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
    }

    /// An endlessly looping GIF with frames of different colors, each shown for 0.02 seconds.
    static func makeGIF(frames: Int) throws -> Data {
        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, frames, nil)
        )
        CGImageDestinationSetProperties(
            destination,
            [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary
        )
        let colors: [UIColor] = [.red, .blue, .yellow, .purple]
        for index in 0..<frames {
            let cgImage = try #require(makeImage(color: colors[index % colors.count]).cgImage)
            CGImageDestinationAddImage(
                destination,
                cgImage,
                [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.02]] as CFDictionary
            )
        }
        try #require(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
