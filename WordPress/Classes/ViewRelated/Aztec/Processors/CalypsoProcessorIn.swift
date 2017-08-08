import Foundation
import Aztec


// MARK: - CalypsoProcessorIn
//
class CalypsoProcessorIn: Processor {

    /// Converts a Calypso-Generated string into Valid HTML that can actually be edited by Aztec.
    ///
    /// Ref. https://github.com/WordPress/WordPress/blob/4e4df0e/wp-admin/js/editor.js#L309
    ///
    func process(text: String) -> String {
        var preserve_linebreaks = false
        var preserve_br = false
        let blocklist = "table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre" +
            "|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section" +
            "|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary"

        // Normalize line breaks.
//      text = text.replace( /\r\n|\r/g, '\n' );
        var output = text.stringByReplacingMatches(of: "\r\n|\r", with: "\n")

//      if ( text.indexOf( '\n' ) === -1 ) {
        guard output.contains("\n") else {
            // return text;
            return output
        }

        // Remove line breaks from <object>
//      if ( text.indexOf( '<object' ) !== -1 ) {
        if output.contains("<object") {
//          text = text.replace( /<object[\s\S]+?<\/object>/g, function( a ) {
            output = output.stringByReplacingMatches(of: "<object[\\s\\S]+?<\\/object>", using: { (match, _) in
//              return a.replace( /\n+/g, '' );
                return match.stringByReplacingMatches(of: "\n+", with: "")
            })
        }

        // Remove line breaks from tags.
//      text = text.replace( /<[^<>]+>/g, function( a ) {
        output = output.stringByReplacingMatches(of: "<[^<>]+>", using: { (match, _) in
//          return a.replace( /[\n\t ]+/g, ' ' );
            return match.stringByReplacingMatches(of: "[\n\t ]+", with: " ")
        })

        // Preserve line breaks in <pre> and <script> tags.
//      if ( text.indexOf( '<pre' ) !== -1 || text.indexOf( '<script' ) !== -1 ) {
        if output.contains("<pre") || output.contains("<script") {
//          preserve_linebreaks = true;
            preserve_linebreaks = true
//          text = text.replace( /<(pre|script)[^>]*>[\s\S]*?<\/\1>/g, function( a ) {
            output = output.stringByReplacingMatches(of: "<(pre|script)[^>]*>[\\s\\S]*?<\\/\\1>", using: { (match, _) in
//              return a.replace( /\n/g, '<wp-line-break>' );
                return match.stringByReplacingMatches(of: "\n", with: "<wp-line-break>")
            })
        }

//      if ( text.indexOf( '<figcaption' ) !== -1 ) {
        if output.contains("<figcaption") {
//          text = text.replace( /\s*(<figcaption[^>]*>)/g, '$1' );
            output = output.stringByReplacingMatches(of: "\\s*(<figcaption[^>]*>)", with: "$1")
//          text = text.replace( /<\/figcaption>\s*/g, '</figcaption>' );
            output = output.stringByReplacingMatches(of: "</figcaption>\\s*", with: "</figcaption>")
        }

        // Keep <br> tags inside captions.
//      if ( text.indexOf( '[caption' ) !== -1 ) {
        if output.contains("[caption") {
//          preserve_br = true;
            preserve_br = true

//          text = text.replace( /\[caption[\s\S]+?\[\/caption\]/g, function( a ) {
            output = output.stringByReplacingMatches(of: "\\[caption[\\s\\S]+?\\[\\/caption\\]", using: { (match, _) in

//              a = a.replace( /<br([^>]*)>/g, '<wp-temp-br$1>' );
                var updated = match.stringByReplacingMatches(of: "<br([^>]*)>", with: "<wp-temp-br$1>")

//              a = a.replace( /<[^<>]+>/g, function( b ) {
                updated = updated.stringByReplacingMatches(of: "<[^<>]+>", using: { (match, _) in
//                  return b.replace( /[\n\t ]+/, ' ' );
                    return match.stringByReplacingMatches(of: "[\n\t ]+", with: " ")
                })

//              return a.replace( /\s*\n\s*/g, '<wp-temp-br />' );
                return updated.stringByReplacingMatches(of: "\\s*\n\\s*", with: "<wp-temp-br />")
            })
        }

//      text = text + '\n\n';
        output = output + "\n\n"

//      text = text.replace( /<br \/>\s*<br \/>/gi, '\n\n' );
        output = output.stringByReplacingMatches(of: "<br \\/>\\s*<br \\/>", with: "\n\n")

        // Pad block tags with two line breaks.
//    text = text.replace( new RegExp( '(<(?:' + blocklist + ')(?: [^>]*)?>)', 'gi' ), '\n\n$1' );
        output = output.stringByReplacingMatches(of: "(<(?:" + blocklist + ")(?: [^>]*)?>)", with: "\n\n$1")
//    text = text.replace( new RegExp( '(</(?:' + blocklist + ')>)', 'gi' ), '$1\n\n' );
        output = output.stringByReplacingMatches(of: "(</(?:" + blocklist + ")>)", with: "$1\n\n")
//    text = text.replace( /<hr( [^>]*)?>/gi, '<hr$1>\n\n' );
        output = output.stringByReplacingMatches(of: "<hr( [^>]*)?>", with: "<hr$1>\n\n")

        // Remove white space chars around <option>.
//    text = text.replace( /\s*<option/gi, '<option' );
        output = output.stringByReplacingMatches(of: "\\s*<option", with: "<option")
//    text = text.replace( /<\/option>\s*/gi, '</option>' );
        output = output.stringByReplacingMatches(of: "<\\/option>\\s*", with: "</option>")

        // Normalize multiple line breaks and white space chars.
//    text = text.replace( /\n\s*\n+/g, '\n\n' );
        output = output.stringByReplacingMatches(of: "\n\\s*\n+", with: "\n\n")

        // Convert two line breaks to a paragraph.
//    text = text.replace( /([\s\S]+?)\n\n/g, '<p>$1</p>\n' );
        output = output.stringByReplacingMatches(of: "([\\s\\S]+?)\n\n", with: "<p>$1</p>\n")

        // Remove empty paragraphs.
//    text = text.replace( /<p>\s*?<\/p>/gi, '');
        output = output.stringByReplacingMatches(of: "<p>\\s*?<\\/p>", with: "")

        // Remove <p> tags that are around block tags.
//    text = text.replace( new RegExp( '<p>\\s*(</?(?:' + blocklist + ')(?: [^>]*)?>)\\s*</p>', 'gi' ), '$1' );
        output = output.stringByReplacingMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$1")
//    text = text.replace( /<p>(<li.+?)<\/p>/gi, '$1');
        output = output.stringByReplacingMatches(of: "<p>(<li.+?)<\\/p>", with: "$1")

        // Fix <p> in blockquotes.
//    text = text.replace( /<p>\s*<blockquote([^>]*)>/gi, '<blockquote$1><p>');
        output = output.stringByReplacingMatches(of: "<p>\\s*<blockquote([^>]*)>", with: "<blockquote$1><p>")
//    text = text.replace( /<\/blockquote>\s*<\/p>/gi, '</p></blockquote>');
        output = output.stringByReplacingMatches(of: "<\\/blockquote>\\s*<\\/p>", with: "</p></blockquote>")

        // Remove <p> tags that are wrapped around block tags.
//    text = text.replace( new RegExp( '<p>\\s*(</?(?:' + blocklist + ')(?: [^>]*)?>)', 'gi' ), '$1' );
        output = output.stringByReplacingMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)", with: "$1")
//    text = text.replace( new RegExp( '(</?(?:' + blocklist + ')(?: [^>]*)?>)\\s*</p>', 'gi' ), '$1' );
        output = output.stringByReplacingMatches(of: "(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$1")
//    text = text.replace( /(<br[^>]*>)\s*\n/gi, '$1' );
        output = output.stringByReplacingMatches(of: "(<br[^>]*>)\\s*\n", with: "$1")

        // Add <br> tags.
//    text = text.replace( /\s*\n/g, '<br />\n');
        output = output.stringByReplacingMatches(of: "\\s*\n", with: "<br />\n")

        // Remove <br> tags that are around block tags.
//    text = text.replace( new RegExp( '(</?(?:' + blocklist + ')[^>]*>)\\s*<br />', 'gi' ), '$1' );
        output = output.stringByReplacingMatches(of: "(</?(?:" + blocklist + ")[^>]*>)\\s*<br />", with: "$1")
//    text = text.replace( /<br \/>(\s*<\/?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)>)/gi, '$1' );
        output = output.stringByReplacingMatches(of: "<br \\/>(\\s*<\\/?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)>)", with: "$1")

        // Remove <p> and <br> around captions.
//    text = text.replace( /(?:<p>|<br ?\/?>)*\s*\[caption([^\[]+)\[\/caption\]\s*(?:<\/p>|<br ?\/?>)*/gi, '[caption$1[/caption]' );
        output = output.stringByReplacingMatches(of: "(?:<p>|<br ?\\/?>)*\\s*\\[caption([^\\[]+)\\[\\/caption\\]\\s*(?:<\\/p>|<br ?\\/?>)*", with: "[caption$1[/caption]")

        // Make sure there is <p> when there is </p> inside block tags that can contain other blocks.
//    text = text.replace( /(<(?:div|th|td|form|fieldset|dd)[^>]*>)(.*?)<\/p>/g, function( a, b, c ) {
        output = output.stringByReplacingMatches(of: "(<(?:div|th|td|form|fieldset|dd)[^>]*>)(.*?)<\\/p>", using: { (match, submatches) in

//        if ( c.match( /<p( [^>]*)?>/ ) ) {
            guard submatches.count < 2 || submatches[1].matches(regex: "<p( [^>]*)?>").count == 0 else {
//            return a;
                return match
            }

//        return b + '<p>' + c + '</p>';
            return submatches[0] + "<p>" + submatches[1] + "</p>"
        })

        // Restore the line breaks in <pre> and <script> tags.
        if preserve_linebreaks {
//            text = text.replace( /<wp-line-break>/g, '\n' );
            output = output.replacingOccurrences(of: "<wp-line-break>", with: "\n")
        }
        
        // Restore the <br> tags in captions.
        if preserve_br {
//            text = text.replace( /<wp-temp-br([^>]*)>/g, '<br$1>' );
            output = output.stringByReplacingMatches(of: "<wp-temp-br([^>]*)>", with: "<br$1>")
        }
        
        return output
    }
}
