import UIKit

extension PostSearchViewModel {
    static func highlight(terms: [String], in attributedString: NSMutableAttributedString) {
        attributedString.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: attributedString.length))

        let string = attributedString.string

        let ranges = terms.flatMap {
            string.ranges(of: $0, options: [.caseInsensitive, .diacriticInsensitive])
        }.sorted { $0.lowerBound < $1.lowerBound }

        for range in collapseAdjacentRanges(ranges, in: string) {
            attributedString.addAttributes([
                .backgroundColor: UIColor.systemYellow.withAlphaComponent(0.25)
            ], range: NSRange(range, in: string))
        }
    }

    // Both decoding & searching are expensive, so the service performs these
    // operations in the background.
    static func higlight(_ title: String, terms: [String]) -> NSAttributedString {
        let title = title
            .trimmingCharacters(in: .whitespaces)
            .stringByDecodingXMLCharacters()

        let ranges = terms.flatMap {
            title.ranges(of: $0, options: [.caseInsensitive, .diacriticInsensitive])
        }.sorted { $0.lowerBound < $1.lowerBound }

        let string = NSMutableAttributedString(string: title, attributes: [
            .font: WPStyleGuide.fontForTextStyle(.body)
        ])
        for range in collapseAdjacentRanges(ranges, in: title) {
            string.setAttributes([
                .backgroundColor: UIColor.systemYellow.withAlphaComponent(0.25)
            ], range: NSRange(range, in: title))
        }
        return string
    }

    private static func collapseAdjacentRanges(_ ranges: [Range<String.Index>], in string: String) -> [Range<String.Index>] {
        var output: [Range<String.Index>] = []
        var ranges = ranges
        while let rhs = ranges.popLast() {
            if let lhs = ranges.last,
               rhs.lowerBound > string.startIndex,
               lhs.upperBound == string.index(before: rhs.lowerBound),
               string[string.index(before: rhs.lowerBound)].isWhitespace {
                ranges.removeLast()
                ranges.append(lhs.lowerBound..<rhs.upperBound)
            } else {
                output.append(rhs)
            }
        }
        return output
    }
}

private extension String {
    func ranges(of string: String, options: String.CompareOptions) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = range(of: string, options: options, range: startIndex..<endIndex) {
            ranges.append(range)
            startIndex = range.upperBound
        }
        return ranges
    }
}
