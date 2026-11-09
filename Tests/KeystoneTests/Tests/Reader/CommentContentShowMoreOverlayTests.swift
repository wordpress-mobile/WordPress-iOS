import Testing
import UIKit
@testable import WordPress

@MainActor
@Suite("CommentContentShowMoreOverlay")
struct CommentContentShowMoreOverlayTests {
    @Test("the fade follows a switch from dark to light mode")
    func fadeFollowsDarkToLight() throws {
        let overlay = CommentContentShowMoreOverlay()

        overlay.traitOverrides.userInterfaceStyle = .dark
        overlay.updateTraitsIfNeeded()
        #expect(try fadeEndColor(of: overlay) == resolved(.systemBackground, .dark))

        overlay.traitOverrides.userInterfaceStyle = .light
        overlay.updateTraitsIfNeeded()
        #expect(try fadeEndColor(of: overlay) == resolved(.systemBackground, .light))
    }

    @Test("the fade uses the color it is given")
    func fadeUsesFadeColor() throws {
        let overlay = CommentContentShowMoreOverlay()
        let sepia = UIColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1)

        overlay.fadeColor = sepia

        #expect(try fadeEndColor(of: overlay) == sepia.cgColor)
    }

    private func fadeEndColor(of overlay: UIView) throws -> CGColor {
        let gradient = try #require(overlay.layer.sublayers?.compactMap { $0 as? CAGradientLayer }.first)
        let colors = try #require(gradient.colors as? [CGColor])
        return try #require(colors.last)
    }

    private func resolved(_ color: UIColor, _ style: UIUserInterfaceStyle) -> CGColor {
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).cgColor
    }
}
