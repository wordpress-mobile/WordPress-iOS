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
        output = output.stringByReplacingMatches(of: "<div( [^>]*)?>\\s*<p>", with: "<div$1>\n\n")

        //                // Remove paragraph tags.
        //                html = html.replace( /\s*<p>/gi, '' );
        output = output.stringByReplacingMatches(of: "\\s*<p>", with: "")

        //                html = html.replace( /\s*<\/p>\s*/gi, '\n\n' );
        output = output.stringByReplacingMatches(of: "\\s*<\\/p>\\s*", with: "\n\n")

        //                // Normalize white space chars and remove multiple line breaks.
        //                html = html.replace( /\n[\s\u00a0]+\n/g, '\n\n' );
        output = output.stringByReplacingMatches(of: "\n[\\s\\u00a0]+\n", with: "\n\n")

        //                // Replace <br> tags with line breaks.
        //                html = html.replace( /(\s*)<br ?\/?>\s*/gi, function( match, space ) {
        output = output.stringByReplacingMatches(of: "(\\s*)<br ?\\/?>\\s*", using: { (match, ranges) -> String in

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
//                
//                // Pad remaining <p> tags whit a line break.
//                html = html.replace( /\s*(<p [^>]+>[\s\S]*?<\/p>)/g, '\n$1' );
//                
//                // Trim.
//                html = html.replace( /^\s+/, '' );
//                html = html.replace( /[\s\u00a0]+$/, '' );
//                
//                if ( preserve_linebreaks ) {
//                html = html.replace( /<wp-line-break>/g, '\n' );
//                }
//                
//                if ( preserve_br ) {
//                html = html.replace( /<wp-temp-br([^>]*)>/g, '<br$1>' );
//                }
//                
//                // Restore preserved tags.
//                if ( preserve.length ) {
//                html = html.replace( /<wp-preserve>/g, function() {
//                return preserve.shift();
//                } );
//                }
//                
//                return html;

        return output
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
