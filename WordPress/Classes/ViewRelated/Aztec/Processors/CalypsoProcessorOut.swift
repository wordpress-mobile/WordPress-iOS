import Foundation
import Aztec


// MARK: - CalypsoProcessorIn
//
class CalypsoProcessorOut: Processor {

    /// Converts the standard-HTML output of Aztec into the hybrid-HTML that WordPress uses to store
    /// posts.
    ///
    /// This method was a direct migration from:
    /// https://github.com/WordPress/WordPress/blob/4e4df0e/wp-admin/js/editor.js#L172
    /// Current as of 2017/08/08
    ///
    func process(_ text: String) -> String {

        guard text.characters.count > 0 else {
            return ""
        }

        let lineBreakMarker = "<wp-line-break>"
        let preserveMarker = "<wp-preserve>"

        var preserveLinebreaks = false
        var preserveBr = false
        var preserve = [String]()
        let blocklist = "blockquote|ul|ol|li|dl|dt|dd|table|thead|tbody|tfoot|tr|th|td|h[1-6]|fieldset|figure"
        let blocklist1 = blocklist + "|div|p"
        let blocklist2 = blocklist + "|pre"

        var output = text

        // Protect script and style tags.
        if output.contains("<script") || output.contains("<style") {
            output = output.replacingMatches(of: "<(script|style)[^>]*>[\\s\\S]*?<\\/\\1>", using: { (match, _) -> String in
                preserve.append(match)

                return preserveMarker
            })
        }

        // Protect pre tags.
        if output.contains("<pre") {
            preserveLinebreaks = true

            output = output.replacingMatches(of: "<pre[^>]*>[\\s\\S]+?<\\/pre>", using: { (match, _) -> String in
                var string = match.replacingMatches(of: "<br ?\\/?>(\r\n|\n)?", with: lineBreakMarker)

                string = string.replacingMatches(of: "<\\/?p( [^>]*)?>(\r\n|\n)?", with: lineBreakMarker)

                return string.replacingMatches(of: "\r?\n", with: lineBreakMarker)
            })
        }

        // Remove line breaks but keep <br> tags inside image captions.
        if output.contains("[caption") {
            preserveBr = true

            output = output.replacingMatches(of: "\\[caption[\\s\\S]+?\\[\\/caption\\]", using: { (match, _) -> String in
                let string = match.replacingMatches(of: "<br([^>]*)>", with: "<wp-temp-br$1>")
                return string.replacingMatches(of: "[\r\n\t]+", with: "")
            })
        }

        // Normalize white space characters before and after block tags.
        output = output.replacingMatches(of: "\\s*</(\(blocklist1))>\\s*", with: "</$1>\n")
        output = output.replacingMatches(of: "\\s*<((?:" + blocklist1 + ")(?: [^>]*)?)>", with: "\n<$1>")

        // Mark </p> if it has any attributes.
        output = output.replacingMatches(of: "(<p [^>]+>.*?)<\\/p>", with: "$1</p#>")

        // Preserve the first <p> inside a <div>.
        output = output.replacingMatches(of: "<div( [^>]*)?>\\s*<p>", with: "<div$1>\n\n", options: .caseInsensitive)

        // Remove paragraph tags.
        output = output.replacingMatches(of: "\\s*<p>", with: "", options: .caseInsensitive)
        output = output.replacingMatches(of: "\\s*<\\/p>\\s*", with: "\n\n", options: .caseInsensitive)

        // Normalize white space chars and remove multiple line breaks.
        output = output.replacingMatches(of: "\n[\\s\\u00a0]+\n", with: "\n\n")

        // Replace <br> tags with line breaks.
        output = output.replacingMatches(of: "(\\s*)<br ?\\/?>\\s*", options: .caseInsensitive, using: { (match, ranges) -> String in
            if ranges.count > 0 && ranges[0].contains("\n") {
                return "\n\n"
            }

            return "\n"
        })

        // Fix line breaks around <div>.
        output = output.replacingMatches(of: "\\s*<div", with: "\n<div")
        output = output.replacingMatches(of: "<\\/div>\\s*", with: "</div>\n")

        // Fix line breaks around caption shortcodes.
        output = output.replacingMatches(of: "\\s*\\[caption([^\\[]+)\\[\\/caption\\]\\s*", with: "\n\n[caption$1[/caption]\n\n")
        output = output.replacingMatches(of: "caption\\]\n\n+\\[caption", with: "caption]\n\n[caption")

        // Pad block elements tags with a line break.
        output = output.replacingMatches(of: "\\s*<((?:" + blocklist2 + ")(?: [^>]*)?)\\s*>", with: "\n<$1>")
        output = output.replacingMatches(of: "\\s*</(' + blocklist2 + ')>\\s*", with: "</$1>\n")

        // Indent <li>, <dt> and <dd> tags.
        output = output.replacingMatches(of: "<((li|dt|dd)[^>]*)>", with: " \t<$1>")

        // Fix line breaks around <select> and <option>.
        if output.contains("<option") {
            output = output.replacingMatches(of: "\\s*<option", with: "\n<option")
            output = output.replacingMatches(of: "\\s*<\\/select>", with: "\n</select>")
        }

        // Pad <hr> with two line breaks.
        if output.contains("<hr") {
            output = output.replacingMatches(of: "\\s*<hr( [^>]*)?>\\s*", with: "\n\n<hr$1>\n\n")
        }

        // Remove line breaks in <object> tags.
        if output.contains("<object") {
            output = output.replacingMatches(of: "<object[\\s\\S]+?<\\/object>", using: { (match, _) -> String in
                return match.replacingMatches(of: "[\r\n]+", with: "")
            })
        }

        // Unmark special paragraph closing tags.
        output = output.replacingMatches(of: "<\\/p#>", with: "</p>\n")

        // Pad remaining <p> tags whit a line break.
        output = output.replacingMatches(of: "\\s*(<p [^>]+>[\\s\\S]*?<\\/p>)", with: "\n$1")

        // Trim.
        output = output.replacingMatches(of: "^\\s+", with: "")
        output = output.replacingMatches(of: "[\\s\\u00a0]+$", with: "")

        if preserveLinebreaks {
            output = output.replacingMatches(of: lineBreakMarker, with: "\n")
        }

        if preserveBr {
            output = output.replacingMatches(of: "<wp-temp-br([^>]*)>", with: "<br$1>")
        }

        // Restore preserved tags.
        if preserve.count > 0 {
            output = output.replacingMatches(of: preserveMarker, using: { (_, _) -> String in
                return preserve.removeFirst()
            })
        }

        //                return html;
        return output
    }
}
