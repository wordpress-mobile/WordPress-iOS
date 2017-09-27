import Foundation
import Aztec


// MARK: - CalypsoProcessorIn
//
class CalypsoProcessorIn: Processor {

    /// Converts a Calypso-Generated string into Valid HTML that can actually be edited by Aztec.
    ///
    /// This method was a direct migration from:
    /// https://github.com/WordPress/WordPress/blob/4e4df0e/wp-admin/js/editor.js#L309
    /// Current as of 2017/08/08
    ///
    func process(_ text: String) -> String {
        var preserveLinebreaks = false
        var preserveBR = false
        let blocklist = "table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre" +
            "|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section" +
            "|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary"

        // Normalize line breaks.
        var output = text.replacingMatches(of: "\r\n|\r", with: "\n")

        guard output.contains("\n") else {
            return output
        }

        // Remove line breaks from <object>
        if output.contains("<object") {
            output = output.replacingMatches(of: "<object[\\s\\S]+?<\\/object>", using: { (match, _) in
                return match.replacingMatches(of: "\n+", with: "")
            })
        }

        // Remove line breaks from tags.
        output = output.replacingMatches(of: "<[^<>]+>", using: { (match, _) in
            return match.replacingMatches(of: "[\n\t ]+", with: " ")
        })

        // Preserve line breaks in <pre> and <script> tags.
        if output.contains("<pre") || output.contains("<script") {
            preserveLinebreaks = true

            output = output.replacingMatches(of: "<(pre|script)[^>]*>[\\s\\S]*?<\\/\\1>", using: { (match, _) in
                return match.replacingMatches(of: "\n", with: "<wp-line-break>")
            })
        }

        if output.contains("<figcaption") {
            output = output.replacingMatches(of: "\\s*(<figcaption[^>]*>)", with: "$1")
            output = output.replacingMatches(of: "</figcaption>\\s*", with: "</figcaption>")
        }

        // Keep <br> tags inside captions.
        if output.contains("[caption") {
            preserveBR = true

            output = output.replacingMatches(of: "\\[caption[\\s\\S]+?\\[\\/caption\\]", using: { (match, _) in
                var updated = match.replacingMatches(of: "<br([^>]*)>", with: "<wp-temp-br$1>")

                updated = updated.replacingMatches(of: "<[^<>]+>", using: { (match, _) in
                    return match.replacingMatches(of: "[\n\t ]+", with: " ")
                })

                return updated.replacingMatches(of: "\\s*\n\\s*", with: "<wp-temp-br />")
            })
        }

        output = output + "\n\n"
        output = output.replacingMatches(of: "<br \\/>\\s*<br \\/>", with: "\n\n", options: .caseInsensitive)

        // Pad block tags with two line breaks.
        output = output.replacingMatches(of: "(<(?:" + blocklist + ")(?: [^>]*)?>)", with: "\n\n$1", options: .caseInsensitive)
        output = output.replacingMatches(of: "(</(?:" + blocklist + ")>)", with: "$1\n\n", options: .caseInsensitive)
        output = output.replacingMatches(of: "<hr( [^>]*)?>", with: "<hr$1>\n\n", options: .caseInsensitive)

        // Remove white space chars around <option>.
        output = output.replacingMatches(of: "\\s*<option", with: "<option", options: .caseInsensitive)
        output = output.replacingMatches(of: "<\\/option>\\s*", with: "</option>", options: .caseInsensitive)

        // Normalize multiple line breaks and white space chars.
        output = output.replacingMatches(of: "\n\\s*\n+", with: "\n\n")

        // Convert two line breaks to a paragraph.
        output = output.replacingMatches(of: "([\\s\\S]+?)\n\n", with: "<p>$1</p>\n")

        // Remove empty paragraphs.
        output = output.replacingMatches(of: "<p>\\s*?<\\/p>", with: "", options: .caseInsensitive)

        // Remove <p> tags that are around block tags.
        output = output.replacingMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$1", options: .caseInsensitive)
        output = output.replacingMatches(of: "<p>(<li.+?)<\\/p>", with: "$1", options: .caseInsensitive)

        // Fix <p> in blockquotes.
        output = output.replacingMatches(of: "<p>\\s*<blockquote([^>]*)>", with: "<blockquote$1><p>", options: .caseInsensitive)
        output = output.replacingMatches(of: "<\\/blockquote>\\s*<\\/p>", with: "</p></blockquote>", options: .caseInsensitive)

        // Remove <p> tags that are wrapped around block tags.
        output = output.replacingMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)", with: "$1", options: .caseInsensitive)
        output = output.replacingMatches(of: "(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$1", options: .caseInsensitive)
        output = output.replacingMatches(of: "(<br[^>]*>)\\s*\n", with: "$1", options: .caseInsensitive)

        // Add <br> tags.
        output = output.replacingMatches(of: "\\s*\n", with: "<br />\n")

        // Remove <br> tags that are around block tags.
        output = output.replacingMatches(of: "(</?(?:" + blocklist + ")[^>]*>)\\s*<br />", with: "$1", options: .caseInsensitive)
        output = output.replacingMatches(of: "<br \\/>(\\s*<\\/?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)>)", with: "$1", options: .caseInsensitive)

        // Remove <p> and <br> around captions.
        output = output.replacingMatches(of: "(?:<p>|<br ?\\/?>)*\\s*\\[caption([^\\[]+)\\[\\/caption\\]\\s*(?:<\\/p>|<br ?\\/?>)*", with: "[caption$1[/caption]", options: .caseInsensitive)

        // Make sure there is <p> when there is </p> inside block tags that can contain other blocks.
        output = output.replacingMatches(of: "(<(?:div|th|td|form|fieldset|dd)[^>]*>)(.*?)<\\/p>", using: { (match, submatches) in
            guard submatches.count < 2 || submatches[1].matches(regex: "<p( [^>]*)?>").count == 0 else {
                return match
            }

            return submatches[0] + "<p>" + submatches[1] + "</p>"
        })

        // Restore the line breaks in <pre> and <script> tags.
        if preserveLinebreaks {
            output = output.replacingOccurrences(of: "<wp-line-break>", with: "\n")
        }

        // Restore the <br> tags in captions.
        if preserveBR {
            output = output.replacingMatches(of: "<wp-temp-br([^>]*)>", with: "<br$1>")
        }

        return output
    }
}
