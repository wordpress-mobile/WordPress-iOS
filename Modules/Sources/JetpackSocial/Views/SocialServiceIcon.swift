import SwiftUI

/// Resolves the icon for a Publicize service using assets shipped inside the
/// JetpackSocial bundle. Returns `nil` when no icon is available — callers
/// should gracefully omit the icon in that case.
///
/// Asset names use the `publicize-` prefix so they don't collide with the
/// main app's `social-*` assets if both bundles are loaded.
enum SocialServiceIcon {
    static func image(forServiceID serviceID: String) -> Image? {
        let normalized = serviceID.lowercased().replacingOccurrences(of: "_", with: "-")
        let mapped = alias(for: normalized) ?? normalized
        return loadImage(name: "publicize-\(mapped)")
            ?? loadImage(name: "publicize-default")
    }

    private static func alias(for serviceID: String) -> String? {
        switch serviceID {
        case "google-plus-1": return "google-plus"
        case "press-this": return "wordpress"
        default: return nil
        }
    }

    private static func loadImage(name: String) -> Image? {
        // SwiftUI's `Image(_:bundle:)` returns non-optional and renders a
        // placeholder for missing assets, so probe via UIImage to detect
        // existence first; UIKit caches the lookup, so the discarded
        // instance is cheap.
        guard UIImage(named: name, in: .module, with: nil) != nil else {
            return nil
        }
        return Image(name, bundle: .module)
    }
}
