import SwiftUI
import UIKit
import Testing
@testable import JetpackStats

@Suite(.serialized)
@MainActor
struct PulseAnimationModifierTests {
    @Test
    func disabledPulsePreservesOverflow() throws {
        let content = Color.gray.frame(width: 120, height: 60)
            .overlay(alignment: .top) {
                Color.red.frame(width: 40, height: 20).offset(y: -25)
            }
        let original = try redPixelCount(in: content)
        let disabledPulse = try redPixelCount(in: content.pulsating(false))

        #expect(original == 800)
        #expect(disabledPulse == original)
    }

    @Test
    func togglingPulsePreservesContentIdentity() async throws {
        var appearances: [UUID] = []
        func content(isEnabled: Bool) -> some View {
            IdentityProbe { appearances.append($0) }
                .pulsating(isEnabled)
        }
        let controller = UIHostingController(rootView: content(isEnabled: true))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 160))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }

        for isEnabled in [true, false, true, false] {
            controller.rootView = content(isEnabled: isEnabled)
            try await Task.sleep(for: .milliseconds(50))
            controller.view.layoutIfNeeded()
        }

        #expect(appearances.count == 1)
    }

    private func redPixelCount(in view: some View) throws -> Int {
        let renderer = ImageRenderer(content: view.frame(width: 200, height: 160).background(Color.white))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try #require(
                CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            )
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return stride(from: 0, to: pixels.count, by: 4)
            .count { index in
                pixels[index] > 200 && pixels[index + 1] < 100 && pixels[index + 2] < 100
            }
    }
}

private struct IdentityProbe: View {
    let onAppear: (UUID) -> Void
    @State private var identity = UUID()

    var body: some View {
        Color.clear.onAppear { onAppear(identity) }
    }
}
