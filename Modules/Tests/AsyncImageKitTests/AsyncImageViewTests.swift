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

    /// Gives the GIF's display link time to deliver several frames, and renders them.
    private func renderFrames(of gifView: GIFImageView) async throws {
        for _ in 0..<30 {
            gifView.layer.displayIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    static func makeImage(color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
            .image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
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
