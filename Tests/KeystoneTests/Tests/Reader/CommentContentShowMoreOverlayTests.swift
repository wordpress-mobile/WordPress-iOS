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

    @Test("the fade matches the gray of a sheet in dark mode")
    func fadeFollowsElevatedLevel() throws {
        let overlay = CommentContentShowMoreOverlay()
        let elevatedDark = UITraitCollection {
            $0.userInterfaceStyle = .dark
            $0.userInterfaceLevel = .elevated
        }

        // The overlay is already dark before it's added to the sheet, so
        // only the level changes.
        overlay.traitOverrides.userInterfaceStyle = .dark
        overlay.updateTraitsIfNeeded()
        overlay.traitOverrides.userInterfaceLevel = .elevated
        overlay.updateTraitsIfNeeded()

        let expected = UIColor.systemBackground.resolvedColor(with: elevatedDark).cgColor
        #expect(expected != resolved(.systemBackground, .dark))
        #expect(try fadeEndColor(of: overlay) == expected)
    }

    @Test("the fade follows Increase Contrast on a sheet in dark mode")
    func fadeFollowsContrast() throws {
        let overlay = CommentContentShowMoreOverlay()
        let sheet = UITraitCollection {
            $0.userInterfaceStyle = .dark
            $0.userInterfaceLevel = .elevated
        }
        let highContrastSheet = sheet.modifyingTraits { $0.accessibilityContrast = .high }

        overlay.traitOverrides.userInterfaceStyle = .dark
        overlay.traitOverrides.userInterfaceLevel = .elevated
        overlay.updateTraitsIfNeeded()
        let normal = UIColor.systemBackground.resolvedColor(with: sheet).cgColor
        #expect(try fadeEndColor(of: overlay) == normal)

        overlay.traitOverrides.accessibilityContrast = .high
        overlay.updateTraitsIfNeeded()
        let highContrast = UIColor.systemBackground.resolvedColor(with: highContrastSheet).cgColor
        #expect(highContrast != normal)
        #expect(try fadeEndColor(of: overlay) == highContrast)
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
