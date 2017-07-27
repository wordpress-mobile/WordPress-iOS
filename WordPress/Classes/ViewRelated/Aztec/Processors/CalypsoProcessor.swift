import Foundation
import Aztec


// MARK: - CalypsoProcessor
//
class CalypsoProcessor: Processor {

    /// Converts a Calypso-Generated string into Valid HTML that can actually be edited by Aztec.
    ///
    func process(text: String) -> String {
        let (substrings, escaped) = escapePreformattedText(in: text)
        let paragraphs = encapsulateParagraphs(in: escaped)
        let linebreaks = replaceLineBreaks(in: paragraphs)
        let unescaped = unescapePreformattedText(in: linebreaks, using: substrings)

        return unescaped
    }
}


// MARK: - Calypso Escaping Helpers
//
private extension CalypsoProcessor {

    /// Escapes Preformatted HTML Elements, and returns a touple containing the 'Original Pre Snippets'
    /// and the actual escaped string.
    ///
    func escapePreformattedText(in string: String) -> ([String], String) {
        var substrings = [String]()
        var escaped = string

        for range in preformattedTextRanges(in: string).reversed() {
            let substring = string.substring(with: range)
            escaped.replaceSubrange(range, with: Constants.escapedSnippetKey)
            substrings.append(substring)
        }

        return (substrings, escaped)
    }


    /// Unescapes Preformatted Text HTML Elements, given a escaped string, and a collection of all of the 
    /// 'Pristine' Pre Element's contents.
    ///
    func unescapePreformattedText(in string: String, using substrings: [String]) -> String {
        var stack = Array(substrings.reversed())
        var output = string

        for range in escapedRanges(in: string).reversed() {
            guard let replacement = stack.popLast() else {
                break
            }

            output.replaceSubrange(range, with: replacement)
        }

        return output
    }
}


// MARK: - Tag Generation Helpers
//
private extension CalypsoProcessor {

    /// Encapsulates all of the paragraphs (split by '\n\n') into the HTML P Element
    ///
    func encapsulateParagraphs(in string: String) -> String {
        let paragraphs = string.components(separatedBy: "\n\n")
        guard paragraphs.count > 1 else {
            return string
        }

        return paragraphs.reduce("") { (result, paragraph) in
            return result + "<p>" + paragraph + "</p>"
        }
    }

    /// Replaces all of the Line Breaks with the HTML Element <br>
    ///
    func replaceLineBreaks(in string: String) -> String {
        return string.replacingOccurrences(of: "\n", with: "<br>")
    }
}


// MARK: - Regex Helpers
//
private extension CalypsoProcessor {

    /// Returns the collection of Swift Ranges pointing towards all of the "<PRE | <SCRIPT" snippets
    ///
    func preformattedTextRanges(in text: String) -> [Range<String.Index>] {
        return rangesOfSubstrings(matching: Constants.preformattedTextRegex, in: text)
    }

    /// Returns the collection of Swift Ranges pointing towards all of the the Calypso-Escaped Snippets
    ///
    func escapedRanges(in text: String) -> [Range<String.Index>] {
        return rangesOfSubstrings(matching: Constants.escapedSnippetKey, in: text)
    }

    /// Returns the collection of Swift Ranges of all of the Pattern matches, in the specified String.
    ///
    private func rangesOfSubstrings(matching pattern: String, in text: String) -> [Range<String.Index>] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return []
        }

        let matches = regex.matches(in: text, options: [], range: text.foundationRangeOfEntireString)
        let ranges = matches.flatMap { text.range(from: $0.range) }

        return ranges
    }
}


// MARK: - Private Helpers
//
private extension CalypsoProcessor {
    struct Constants {
        static let escapedSnippetKey = "<calypso-escaped>"
        static let preformattedTextRegex = "<(pre|script|ul|ol)[^>]*>[\\s\\S]+?</\\1>"
    }
}
