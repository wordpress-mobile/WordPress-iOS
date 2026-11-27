import Foundation

/// Rebuilds a comment's HTML from a notification's comment block.
///
/// The notifications API sends a comment as plain text plus ranges. Most range types are the names of the
/// HTML tags they came from (`p`, `a`, `li`, …), and their indices are UTF-16 offsets into the text.
enum NotificationCommentHTML {

    /// Returns `text` as HTML, marked up with the tags that `ranges` describe.
    ///
    /// Tags outside an allowlist are dropped, and links keep only `http` and `https` URLs, so the result is
    /// safe to render.
    static func html(text: String, ranges: [[String: Any]]) -> String {
        let units = Array(text.utf16)
        let bounds = trimmedBounds(of: units)
        let elements = makeElements(from: ranges, within: bounds)
        let hasBlocks = elements.contains { blockTags.contains($0.tag) }

        let boundaries = Set([bounds.lowerBound, bounds.upperBound] + elements.flatMap { [$0.start, $0.end] }).sorted()
        var pending = elements.sorted(by: Element.opensBefore)[...]
        var open: [Element] = []
        var html = ""

        for (index, position) in boundaries.enumerated() {
            while let innermost = open.last, innermost.end <= position {
                html += innermost.closingTag
                open.removeLast()
            }
            while let next = pending.first, next.start == position {
                html += next.openingTag
                open.append(next)
                pending.removeFirst()
            }
            guard index + 1 < boundaries.count else {
                break
            }
            let segment = String(decoding: units[position..<boundaries[index + 1]], as: UTF16.self)
            html += render(segment, inside: open, hasBlocks: hasBlocks)
        }
        for element in open.reversed() {
            html += element.closingTag
        }
        return html
    }

    /// Escapes `text` for use in HTML text or a quoted attribute value.
    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

private extension NotificationCommentHTML {

    struct Element {
        let tag: String
        let href: String?
        let start: Int
        let end: Int
        /// How many ranges enclose this one, from the `parent` ids. Orders ranges that cover the same text.
        let depth: Int
        let order: Int

        var openingTag: String {
            href.map { "<a href=\"\(NotificationCommentHTML.escape($0))\">" } ?? "<\(tag)>"
        }

        var closingTag: String {
            "</\(tag)>"
        }

        static func opensBefore(_ lhs: Element, _ rhs: Element) -> Bool {
            (lhs.start, -lhs.end, lhs.depth, lhs.order) < (rhs.start, -rhs.end, rhs.depth, rhs.order)
        }
    }

    static let blockTags: Set<String> = [
        "p", "div", "blockquote", "pre", "ul", "ol", "li", "h1", "h2", "h3", "h4", "h5", "h6"
    ]

    /// Blocks that hold other blocks. Newlines directly inside them are layout from the original HTML, not line breaks.
    static let containerTags: Set<String> = ["div", "blockquote", "ul", "ol"]

    static let inlineTags: Set<String> = [
        "span", "b", "strong", "i", "em", "u", "s", "del", "strike", "code", "sub", "sup", "cite", "q", "small", "mark"
    ]

    static let linkTypes: Set<String> = ["a", "link", "user", "post", "comment", "site"]

    static func makeElements(from ranges: [[String: Any]], within bounds: Range<Int>) -> [Element] {
        var parents: [String: String] = [:]
        for range in ranges {
            if let id = identifier(range["id"]), let parent = identifier(range["parent"]) {
                parents[id] = parent
            }
        }

        return ranges.enumerated()
            .compactMap { order, range in
                guard let type = range["type"] as? String,
                    let indices = range["indices"] as? [Int],
                    indices.count == 2
                else {
                    return nil
                }
                let start = max(indices[0], bounds.lowerBound)
                let end = min(indices[1], bounds.upperBound)
                guard start < end else {
                    return nil
                }

                let tag: String
                let href: String?
                if linkTypes.contains(type) {
                    guard let url = range["url"] as? String, isSafeLink(url) else {
                        return nil
                    }
                    tag = "a"
                    href = url
                } else if blockTags.contains(type) || inlineTags.contains(type) {
                    tag = type
                    href = nil
                } else {
                    return nil
                }

                let depth = depthOf(identifier(range["id"]), parents: parents)
                return Element(tag: tag, href: href, start: start, end: end, depth: depth, order: order)
            }
    }

    static func render(_ segment: String, inside open: [Element], hasBlocks: Bool) -> String {
        if open.contains(where: { $0.tag == "pre" }) {
            return escape(segment)
        }

        let innermostBlock = open.last { blockTags.contains($0.tag) }
        let isLayout = innermostBlock.map { containerTags.contains($0.tag) } ?? hasBlocks
        guard isLayout else {
            return lineBreaks(escape(segment))
        }

        // Whitespace between blocks renders as nothing. Text that sits directly in a container keeps its line breaks.
        if segment.allSatisfy(\.isWhitespace) {
            return segment
        }
        return lineBreaks(escape(segment.trimmingCharacters(in: .newlines)))
    }

    static func lineBreaks(_ html: String) -> String {
        html.replacingOccurrences(of: "\n", with: "<br>")
    }

    static func trimmedBounds(of units: [UTF16.CodeUnit]) -> Range<Int> {
        let isWhitespace: (UTF16.CodeUnit) -> Bool = { [9, 10, 13, 32].contains($0) }
        let start = units.firstIndex { !isWhitespace($0) } ?? units.count
        let end = (units.lastIndex { !isWhitespace($0) }).map { $0 + 1 } ?? start
        return start..<max(start, end)
    }

    static func isSafeLink(_ url: String) -> Bool {
        guard let scheme = URL(string: url)?.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    static func identifier(_ value: Any?) -> String? {
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    static func depthOf(_ id: String?, parents: [String: String]) -> Int {
        var depth = 0
        var current = id
        // The limit guards against a cycle in malformed data.
        while let id = current, let parent = parents[id], depth < 32 {
            depth += 1
            current = parent
        }
        return depth
    }
}
