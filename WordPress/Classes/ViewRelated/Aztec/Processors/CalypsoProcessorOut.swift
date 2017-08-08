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
    func process(text: String) -> String {

        // if ( ! html ) {
        guard text.characters.count > 0 else {
            // return '';
            return ""
        }

        let lineBreakMarker = "<wp-line-break>"

        var preserveLinebreaks = false
        var preserveBr = false
        var preserve = [String]()
        let blocklist = "blockquote|ul|ol|li|dl|dt|dd|table|thead|tbody|tfoot|tr|th|td|h[1-6]|fieldset|figure"
        let blocklist1 = blocklist + "|div|p"
        let blocklist2 = blocklist + "|pre"

        var output = text

        //        // Protect script and style tags.
        //        if ( html.indexOf( '<script' ) !== -1 || html.indexOf( '<style' ) !== -1 ) {
        if output.contains("<script") || output.contains("<style") {
            //            html = html.replace( /<(script|style)[^>]*>[\s\S]*?<\/\1>/g, function( match ) {
            output = output.stringByReplacingMatches(of: "<(script|style)[^>]*>[\\s\\S]*?<\\/\\1>", using: { (match, _) -> String in
                //                preserve.push( match );
                preserve.append(match)

                //                return '<wp-preserve>';
                return "<wp-preserve>"
            })
        }

        //        // Protect pre tags.
        //        if ( html.indexOf( '<pre' ) !== -1 ) {
        if output.contains("<pre") {
            //            preserve_linebreaks = true;
            preserveLinebreaks = true

            //            html = html.replace( /<pre[^>]*>[\s\S]+?<\/pre>/g, function( a ) {
            output = output.stringByReplacingMatches(of: "<pre[^>]*>[\\s\\S]+?<\\/pre>", using: { (match, _) -> String in
                //                a = a.replace( /<br ?\/?>(\r\n|\n)?/g, '<wp-line-break>' );
                var string = match.stringByReplacingMatches(of: "<br ?\\/?>(\r\n|\n)?", with: lineBreakMarker)

                //                a = a.replace( /<\/?p( [^>]*)?>(\r\n|\n)?/g, '<wp-line-break>' );
                string = string.stringByReplacingMatches(of: "<\\/?p( [^>]*)?>(\r\n|\n)?", with: lineBreakMarker)

                //                return a.replace( /\r?\n/g, '<wp-line-break>' );
                return string.stringByReplacingMatches(of: "\r?\n", with: lineBreakMarker)
            })
        }

        //        // Remove line breaks but keep <br> tags inside image captions.
        //        if ( html.indexOf( '[caption' ) !== -1 ) {
        if output.contains("[caption") {
            //            preserve_br = true;
            preserveBr = true

            //            html = html.replace( /\[caption[\s\S]+?\[\/caption\]/g, function( a ) {
            output = output.stringByReplacingMatches(of: "\\[caption[\\s\\S]+?\\[\\/caption\\]", using: { (match, _) -> String in
                //                return a.replace( /<br([^>]*)>/g, '<wp-temp-br$1>' ).replace( /[\r\n\t]+/, '' );
                let string = match.stringByReplacingMatches(of: "<br([^>]*)>", with: "<wp-temp-br$1>")
                return string.stringByReplacingMatches(of: "[\r\n\t]+", with: "")
            })
        }

        //                // Normalize white space characters before and after block tags.
        //                html = html.replace( new RegExp( '\\s*</(' + blocklist1 + ')>\\s*', 'g' ), '</$1>\n' );
        output = output.stringByReplacingMatches(of: "\\s*</(\(blocklist1))>\\s*", with: "</$1>\n")

        //                html = html.replace( new RegExp( '\\s*<((?:' + blocklist1 + ')(?: [^>]*)?)>', 'g' ), '\n<$1>' );
        output = output.stringByReplacingMatches(of: "\\s*<((?:" + blocklist1 + ")(?: [^>]*)?)>", with: "\n<$1>")

        //                // Mark </p> if it has any attributes.
        //                html = html.replace( /(<p [^>]+>.*?)<\/p>/g, '$1</p#>' );
        output = output.stringByReplacingMatches(of: "(<p [^>]+>.*?)<\\/p>", with: "$1</p#>")

        //                // Preserve the first <p> inside a <div>.
        //                html = html.replace( /<div( [^>]*)?>\s*<p>/gi, '<div$1>\n\n' );
        output = output.stringByReplacingMatches(of: "<div( [^>]*)?>\\s*<p>", with: "<div$1>\n\n", options: .caseInsensitive)

        //                // Remove paragraph tags.
        //                html = html.replace( /\s*<p>/gi, '' );
        output = output.stringByReplacingMatches(of: "\\s*<p>", with: "", options: .caseInsensitive)

        //                html = html.replace( /\s*<\/p>\s*/gi, '\n\n' );
        output = output.stringByReplacingMatches(of: "\\s*<\\/p>\\s*", with: "\n\n", options: .caseInsensitive)

        //                // Normalize white space chars and remove multiple line breaks.
        //                html = html.replace( /\n[\s\u00a0]+\n/g, '\n\n' );
        output = output.stringByReplacingMatches(of: "\n[\\s\\u00a0]+\n", with: "\n\n")

        //                // Replace <br> tags with line breaks.
        //                html = html.replace( /(\s*)<br ?\/?>\s*/gi, function( match, space ) {
        output = output.stringByReplacingMatches(of: "(\\s*)<br ?\\/?>\\s*", options: .caseInsensitive, using: { (match, ranges) -> String in

            //                if ( space && space.indexOf( '\n' ) !== -1 ) {
            if ranges.count > 0 && ranges[0].contains("\n") {
                //                return '\n\n';
                return "\n\n"
            }

            //                return '\n';
            return "\n"
        })

        //                // Fix line breaks around <div>.
        //                html = html.replace( /\s*<div/g, '\n<div' );
        output = output.stringByReplacingMatches(of: "\\s*<div", with: "\n<div")

        //                html = html.replace( /<\/div>\s*/g, '</div>\n' );
        output = output.stringByReplacingMatches(of: "<\\/div>\\s*", with: "</div>\n")

        //                // Fix line breaks around caption shortcodes.
        //                html = html.replace( /\s*\[caption([^\[]+)\[\/caption\]\s*/gi, '\n\n[caption$1[/caption]\n\n' );
        output = output.stringByReplacingMatches(of: "\\s*\\[caption([^\\[]+)\\[\\/caption\\]\\s*", with: "\n\n[caption$1[/caption]\n\n")

        //                html = html.replace( /caption\]\n\n+\[caption/g, 'caption]\n\n[caption' );
        output = output.stringByReplacingMatches(of: "caption\\]\n\n+\\[caption", with: "caption]\n\n[caption")

        //                // Pad block elements tags with a line break.
        //                html = html.replace( new RegExp('\\s*<((?:' + blocklist2 + ')(?: [^>]*)?)\\s*>', 'g' ), '\n<$1>' );
        output = output.stringByReplacingMatches(of: "\\s*<((?:" + blocklist2 + ")(?: [^>]*)?)\\s*>", with: "\n<$1>")

        //                html = html.replace( new RegExp('\\s*</(' + blocklist2 + ')>\\s*', 'g' ), '</$1>\n' );
        output = output.stringByReplacingMatches(of: "\\s*</(' + blocklist2 + ')>\\s*", with: "</$1>\n")

        //                // Indent <li>, <dt> and <dd> tags.
        //                html = html.replace( /<((li|dt|dd)[^>]*)>/g, ' \t<$1>' );
        output = output.stringByReplacingMatches(of: "<((li|dt|dd)[^>]*)>", with: " \t<$1>")

        //                // Fix line breaks around <select> and <option>.
        //                if ( html.indexOf( '<option' ) !== -1 ) {
        if output.contains("<option") {
            //                html = html.replace( /\s*<option/g, '\n<option' );
            output = output.stringByReplacingMatches(of: "\\s*<option", with: "\n<option")

            //                html = html.replace( /\s*<\/select>/g, '\n</select>' );
            output = output.stringByReplacingMatches(of: "\\s*<\\/select>", with: "\n</select>")
        }

        //                // Pad <hr> with two line breaks.
        //                if ( html.indexOf( '<hr' ) !== -1 ) {
        if output.contains("<hr") {
            //                html = html.replace( /\s*<hr( [^>]*)?>\s*/g, '\n\n<hr$1>\n\n' );
            output = output.stringByReplacingMatches(of: "\\s*<hr( [^>]*)?>\\s*", with: "\n\n<hr$1>\n\n")
        }

        //                // Remove line breaks in <object> tags.
        //                if ( html.indexOf( '<object' ) !== -1 ) {
        if output.contains("<object") {
            //                html = html.replace( /<object[\s\S]+?<\/object>/g, function( a ) {
            output = output.stringByReplacingMatches(of: "<object[\\s\\S]+?<\\/object>", using: { (match, _) -> String in
                //                return a.replace( /[\r\n]+/g, '' );
                return match.stringByReplacingMatches(of: "[\r\n]+", with: "")
            })
        }

        //                // Unmark special paragraph closing tags.
        //                html = html.replace( /<\/p#>/g, '</p>\n' );
        output = output.stringByReplacingMatches(of: "<\\/p#>", with: "</p>\n")

        //                // Pad remaining <p> tags whit a line break.
        //                html = html.replace( /\s*(<p [^>]+>[\s\S]*?<\/p>)/g, '\n$1' );
        output = output.stringByReplacingMatches(of: "\\s*(<p [^>]+>[\\s\\S]*?<\\/p>)", with: "\n$1")

        //                // Trim.
        //                html = html.replace( /^\s+/, '' );
        output = output.stringByReplacingMatches(of: "^\\s+", with: "")

        //                html = html.replace( /[\s\u00a0]+$/, '' );
        output = output.stringByReplacingMatches(of: "[\\s\\u00a0]+$", with: "")

        //                if ( preserve_linebreaks ) {
        if preserveLinebreaks {
            //                html = html.replace( /<wp-line-break>/g, '\n' );
            output = output.stringByReplacingMatches(of: lineBreakMarker, with: "\n")
        }

        //                if ( preserve_br ) {
        if preserveBr {
            //                html = html.replace( /<wp-temp-br([^>]*)>/g, '<br$1>' );
            output = output.stringByReplacingMatches(of: "<wp-temp-br([^>]*)>", with: "<br$1>")
        }

        //                // Restore preserved tags.
        //                if ( preserve.length ) {
        if preserve.count > 0 {
            //                html = html.replace( /<wp-preserve>/g, function() {
            output = output.stringByReplacingMatches(of: "<wp-preserve>", using: { (_, _) -> String in
                return preserve[0]
            })
        }

        //                return html;
        return output
    }
}

