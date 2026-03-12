import Foundation
import SwiftSoup

public enum ReaderPostParser {
    public enum InteractiveElement: Sendable {
        case gallery(Gallery)
    }

    public struct Gallery: Sendable {
        public let images: [GalleryImage]
    }

    public struct GalleryImage: Sendable {
        /// URL from the `src` attribute (displayed, possibly resized).
        public let src: URL
        /// Full-resolution URL from `data-orig-file`.
        public let originalFileURL: URL?
        /// Original dimensions from `data-orig-size` (e.g. "4032,3024").
        public let originalSize: CGSize?
        /// All srcset variants with their width descriptors.
        public let srcset: [SrcsetEntry]
        /// From `data-image-description`.
        public let description: String?
        /// From `data-image-caption`.
        public let caption: String?
    }

    public struct SrcsetEntry: Sendable {
        public let url: URL
        public let width: Int
    }

    /// Parses post HTML and returns interactive elements (galleries).
    public static func parse(_ html: String) -> [InteractiveElement] {
        guard let document = try? SwiftSoup.parse(html) else {
            return []
        }

        var elements: [InteractiveElement] = []

        // Supported gallery selectors (order matters for specificity)
        let selectors = [
            "figure.wp-block-gallery",
            "div.wp-block-gallery",
            "figure.wp-block-jetpack-tiled-gallery",
            "div.wp-block-jetpack-tiled-gallery",
            "div.tiled-gallery",
            "div.gallery"
        ]

        for selector in selectors {
            guard let containers = try? document.select(selector) else { continue }
            for container in containers {
                let images = parseImages(from: container)
                if !images.isEmpty {
                    elements.append(.gallery(Gallery(images: images)))
                }
                // Remove the container so nested galleries aren't matched again
                try? container.remove()
            }
        }

        return elements
    }

    private static func parseImages(from container: Element) -> [GalleryImage] {
        guard let imgElements = try? container.select("img") else {
            return []
        }
        return imgElements.compactMap { parseImage(from: $0) }
    }

    private static func parseImage(from img: Element) -> GalleryImage? {
        guard let srcString = try? img.attr("src"),
              !srcString.isEmpty,
              let src = URL(string: srcString) else {
            return nil
        }

        let originalFileURL: URL? = {
            guard let value = try? img.attr("data-orig-file"), !value.isEmpty else { return nil }
            return URL(string: value)
        }()

        let originalSize: CGSize? = {
            guard let value = try? img.attr("data-orig-size"), !value.isEmpty else { return nil }
            return parseSize(value)
        }()

        let srcset: [SrcsetEntry] = {
            guard let value = try? img.attr("srcset"), !value.isEmpty else { return [] }
            return parseSrcset(value)
        }()

        let description: String? = {
            guard let value = try? img.attr("data-image-description"), !value.isEmpty else { return nil }
            // Strip HTML tags from description
            return try? SwiftSoup.clean(value, Whitelist.none())
        }()

        let caption: String? = {
            guard let value = try? img.attr("data-image-caption"), !value.isEmpty else { return nil }
            // Strip HTML tags from caption
            return try? SwiftSoup.clean(value, Whitelist.none())
        }()

        return GalleryImage(
            src: src,
            originalFileURL: originalFileURL,
            originalSize: originalSize,
            srcset: srcset,
            description: description,
            caption: caption
        )
    }

    /// Parses "W,H" format (e.g. "4032,3024") into CGSize.
    private static func parseSize(_ value: String) -> CGSize? {
        let parts = value.split(separator: ",")
        guard parts.count == 2,
              let width = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let height = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    /// Parses srcset string (e.g. "url1 300w, url2 600w") into entries.
    private static func parseSrcset(_ value: String) -> [SrcsetEntry] {
        value.split(separator: ",").compactMap { entry in
            let parts = entry.trimmingCharacters(in: .whitespaces).split(separator: " ")
            guard parts.count == 2,
                  let url = URL(string: String(parts[0])),
                  let widthStr = parts[1].dropLast().description.nilIfEmpty,
                  let width = Int(widthStr) else {
                return nil
            }
            return SrcsetEntry(url: url, width: width)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
