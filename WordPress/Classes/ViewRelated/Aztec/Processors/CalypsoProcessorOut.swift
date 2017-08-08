import Foundation
import Aztec


// MARK: - CalypsoProcessorIn
//
class CalypsoProcessorOut: Processor {

    /// Converts a Calypso-Generated string into Valid HTML that can actually be edited by Aztec.
    ///
    /// Ref. https://github.com/WordPress/WordPress/blob/4e4df0e/wp-admin/js/editor.js#L309
    ///
    func process(text: String) -> String {
// - Reventar el `/` inicial
// - Duplicar los `\`
// - Reventar el `/g` final

        var preserve_linebreaks = false
        var preserve_br = false
        let blocklist = "table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre" +
            "|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section" +
            "|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary"

        // Normalize line breaks.
        var output = text.replaceMatches(of: "\r\n|\r", with: "\n")

        guard output.contains("\n") else {
            return output
        }

        // Remove line breaks from <object>
        if output.contains("<object") {
//        text = text.replace( /<object[\s\S]+?<\/object>/g, function( a ) {
//            return a.replace( /\n+/g, '' );
//        });
        }

        // Remove line breaks from tags.
//    text = text.replace( /<[^<>]+>/g, function( a ) {
//        return a.replace( /[\n\t ]+/g, ' ' );
//    });

        // Preserve line breaks in <pre> and <script> tags.
        if output.contains("<pre") || output.contains("<script") {
            preserve_linebreaks = true
//        text = text.replace( /<(pre|script)[^>]*>[\s\S]*?<\/\1>/g, function( a ) {
//            return a.replace( /\n/g, '<wp-line-break>' );
//        });
        }

        if output.contains("<figcaption") {
            output = output.replaceMatches(of: "\\s*(<figcaption[^>]*>)", with: "$0")
            output = output.replaceMatches(of: "</figcaption>\\s*", with: "</figcaption>")
        }

        // Keep <br> tags inside captions.
        if output.contains("[caption") {
            preserve_br = true

//        text = text.replace( /\[caption[\s\S]+?\[\/caption\]/g, function( a ) {
//            a = a.replace( /<br([^>]*)>/g, '<wp-temp-br$1>' );
//
//            a = a.replace( /<[^<>]+>/g, function( b ) {
//                return b.replace( /[\n\t ]+/, ' ' );
//            });
//
//            return a.replace( /\s*\n\s*/g, '<wp-temp-br />' );
//        });
        }

        output = output + "\n\n"
        output = output.replaceMatches(of: "<br \\/>\\s*<br \\/>", with: "\n\n")

        // Pad block tags with two line breaks.
        output = output.replaceMatches(of: "(<(?:" + blocklist + ")(?: [^>]*)?>)", with: "\n\n$0")
        output = output.replaceMatches(of: "(</(?:" + blocklist + ")>)", with: "$0\n\n")
        output = output.replaceMatches(of: "<hr( [^>]*)?>", with: "<hr$0>\n\n")

        // Remove white space chars around <option>.
        output = output.replaceMatches(of: "\\s*<option", with: "<option")
        output = output.replaceMatches(of: "</option>\\s*", with: "</option>")

        // Normalize multiple line breaks and white space chars.
        output = output.replaceMatches(of: "\n\\s*\n+", with: "\n\n")

        // Convert two line breaks to a paragraph.
        output = output.replaceMatches(of: "([\\s\\S]+?)\n\n", with: "<p>$0</p>\n")

        // Remove empty paragraphs.
        output = output.replaceMatches(of: "<p>\\s*?</p>", with: "")

        // Remove <p> tags that are around block tags.
        output = output.replaceMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$0")
        output = output.replaceMatches(of: "<p>(<li.+?)<\\/p>", with: "$0")

        // Fix <p> in blockquotes.
        output = output.replaceMatches(of: "<p>\\s*<blockquote([^>]*)>", with: "<blockquote$0><p>")
        output = output.replaceMatches(of: "<\\/blockquote>\\s*<\\/p>", with: "</p></blockquote>")

        // Remove <p> tags that are wrapped around block tags.
        output = output.replaceMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)", with: "$0")
        output = output.replaceMatches(of: "(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$0")

        output = output.replaceMatches(of: "(<br[^>]*>)\\s*\n", with: "$0")

        // Add <br> tags.
        output = output.replaceMatches(of: "\\s*\n", with: "<br />\n")

        // Remove <br> tags that are around block tags.
        output = output.replaceMatches(of: "(</?(?:" + blocklist + ")[^>]*>)\\s*<br />", with: "$0")
        output = output.replaceMatches(of: "<br />(\\s*<\\/?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)>)", with: "$0")

        // Remove <p> and <br> around captions.
        output = output.replaceMatches(of: "(?:<p>|<br ?\\/?>)*\\s*\\[caption([^\\[]+)\\[\\/caption\\]\\s*(?:<\\/p>|<br ?\\/?>)*", with: "[caption$0[/caption]")

//    // Make sure there is <p> when there is </p> inside block tags that can contain other blocks.
//    text = text.replace( /(<(?:div|th|td|form|fieldset|dd)[^>]*>)(.*?)<\/p>/g, function( a, b, c ) {
//        if ( c.match( /<p( [^>]*)?>/ ) ) {
//            return a;
//        }
//        
//        return b + '<p>' + c + '</p>';
//    });

        // Restore the line breaks in <pre> and <script> tags.
        if preserve_linebreaks {
            output = output.replacingOccurrences(of: "<wp-line-break>", with: "\n")
        }
        
        // Restore the <br> tags in captions.
        if preserve_br {
            output = output.replaceMatches(of: "<wp-temp-br([^>]*)>", with: "<br$0>")
        }
        
        return text
    }
}




//function autop( text ) {
//    var preserve_linebreaks = false,
//        preserve_br = false,
//		blocklist = 'table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre' +
//            '|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section' +
//            '|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary';
//
//    // Normalize line breaks.
//    text = text.replace( /\r\n|\r/g, '\n' );
//
//    if ( text.indexOf( '\n' ) === -1 ) {
//        return text;
//    }
//
//    // Remove line breaks from <object>.
//    if ( text.indexOf( '<object' ) !== -1 ) {
//        text = text.replace( /<object[\s\S]+?<\/object>/g, function( a ) {
//            return a.replace( /\n+/g, '' );
//        });
//    }
//
//    // Remove line breaks from tags.
//    text = text.replace( /<[^<>]+>/g, function( a ) {
//        return a.replace( /[\n\t ]+/g, ' ' );
//    });
//
//    // Preserve line breaks in <pre> and <script> tags.
//    if ( text.indexOf( '<pre' ) !== -1 || text.indexOf( '<script' ) !== -1 ) {
//        preserve_linebreaks = true;
//        text = text.replace( /<(pre|script)[^>]*>[\s\S]*?<\/\1>/g, function( a ) {
//            return a.replace( /\n/g, '<wp-line-break>' );
//        });
//    }
//
//    if ( text.indexOf( '<figcaption' ) !== -1 ) {
//        text = text.replace( /\s*(<figcaption[^>]*>)/g, '$1' );
//        text = text.replace( /<\/figcaption>\s*/g, '</figcaption>' );
//    }
//
//    // Keep <br> tags inside captions.
//    if ( text.indexOf( '[caption' ) !== -1 ) {
//        preserve_br = true;
//
//        text = text.replace( /\[caption[\s\S]+?\[\/caption\]/g, function( a ) {
//            a = a.replace( /<br([^>]*)>/g, '<wp-temp-br$1>' );
//
//            a = a.replace( /<[^<>]+>/g, function( b ) {
//                return b.replace( /[\n\t ]+/, ' ' );
//            });
//
//            return a.replace( /\s*\n\s*/g, '<wp-temp-br />' );
//        });
//    }
//
//    text = text + '\n\n';
//    text = text.replace( /<br \/>\s*<br \/>/gi, '\n\n' );
//
//    // Pad block tags with two line breaks.
//    text = text.replace( new RegExp( '(<(?:' + blocklist + ')(?: [^>]*)?>)', 'gi' ), '\n\n$1' );
//    text = text.replace( new RegExp( '(</(?:' + blocklist + ')>)', 'gi' ), '$1\n\n' );
//    text = text.replace( /<hr( [^>]*)?>/gi, '<hr$1>\n\n' );
//
//    // Remove white space chars around <option>.
//    text = text.replace( /\s*<option/gi, '<option' );
//    text = text.replace( /<\/option>\s*/gi, '</option>' );
//
//    // Normalize multiple line breaks and white space chars.
//    text = text.replace( /\n\s*\n+/g, '\n\n' );
//
//    // Convert two line breaks to a paragraph.
//    text = text.replace( /([\s\S]+?)\n\n/g, '<p>$1</p>\n' );
//
//    // Remove empty paragraphs.
//    text = text.replace( /<p>\s*?<\/p>/gi, '');
//
//    // Remove <p> tags that are around block tags.
//    text = text.replace( new RegExp( '<p>\\s*(</?(?:' + blocklist + ')(?: [^>]*)?>)\\s*</p>', 'gi' ), '$1' );
//    text = text.replace( /<p>(<li.+?)<\/p>/gi, '$1');
//
//    // Fix <p> in blockquotes.
//    text = text.replace( /<p>\s*<blockquote([^>]*)>/gi, '<blockquote$1><p>');
//    text = text.replace( /<\/blockquote>\s*<\/p>/gi, '</p></blockquote>');
//
//    // Remove <p> tags that are wrapped around block tags.
//    text = text.replace( new RegExp( '<p>\\s*(</?(?:' + blocklist + ')(?: [^>]*)?>)', 'gi' ), '$1' );
//    text = text.replace( new RegExp( '(</?(?:' + blocklist + ')(?: [^>]*)?>)\\s*</p>', 'gi' ), '$1' );
//
//    text = text.replace( /(<br[^>]*>)\s*\n/gi, '$1' );
//
//    // Add <br> tags.
//    text = text.replace( /\s*\n/g, '<br />\n');
//
//    // Remove <br> tags that are around block tags.
//    text = text.replace( new RegExp( '(</?(?:' + blocklist + ')[^>]*>)\\s*<br />', 'gi' ), '$1' );
//    text = text.replace( /<br \/>(\s*<\/?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)>)/gi, '$1' );
//
//    // Remove <p> and <br> around captions.
//    text = text.replace( /(?:<p>|<br ?\/?>)*\s*\[caption([^\[]+)\[\/caption\]\s*(?:<\/p>|<br ?\/?>)*/gi, '[caption$1[/caption]' );
//    
//    // Make sure there is <p> when there is </p> inside block tags that can contain other blocks.
//    text = text.replace( /(<(?:div|th|td|form|fieldset|dd)[^>]*>)(.*?)<\/p>/g, function( a, b, c ) {
//        if ( c.match( /<p( [^>]*)?>/ ) ) {
//            return a;
//        }
//        
//        return b + '<p>' + c + '</p>';
//    });
//    
//    // Restore the line breaks in <pre> and <script> tags.
//    if ( preserve_linebreaks ) {
//            text = text.replace( /<wp-line-break>/g, '\n' );
//    }
//    
//    // Restore the <br> tags in captions.
//    if ( preserve_br ) {
//            text = text.replace( /<wp-temp-br([^>]*)>/g, '<br$1>' );
//    }
//    
//    return text;
//}
