import Foundation
import Aztec

public struct VideoProcessor {

    static public var videoPressScheme = "videopress"
    static public var videoPressHTMLAttribute = "data-wpvideopress"
    /// Shortcode processor to process videopress shortcodes to html video element
    /// More info here: https://en.support.wordpress.com/videopress/
    ///
    static public var videoPressPreProcessor: Processor {
        let videoPressProcessor = ShortcodeProcessor(tag:"wpvideo", replacer: { (shortcode) in
        var html = "<video "
        if let src = shortcode.attributes.unamed.first {
            html += "src=\"\(videoPressScheme)://\(src)\" "
            html += "data-wpvideopress=\"\(src)\" "
            html += "poster=\"\(videoPressScheme)://\(src)\" "
        }
        if let width = shortcode.attributes.named["w"] {
            html += "width=\(width) "
        }
        if let height = shortcode.attributes.named["h"] {
            html += "height=\(height) "
        }

        html += "/>"
        return html
        })
        return videoPressProcessor
    }

    /// Shortcode processor to process html video elements to videopress shortcodes
    /// More info here: https://en.support.wordpress.com/videopress/
    ///
    static public var videoPressPostProcessor: Processor {
        let postWordPressVideoProcessor = HTMLProcessor(tag:"video", replacer: { (shortcode) in
            guard let videoPressID = shortcode.attributes.named[videoPressHTMLAttribute] else {
                return nil
            }
            var html = "[wpvideo \(videoPressID) "
            if let width = shortcode.attributes.named["width"] {
                html += "w=\(width) "
            }
            if let height = shortcode.attributes.named["height"] {
                html += "h=\(height) "
            }
            html += "]"
            return html
        })
        return postWordPressVideoProcessor
    }

    /// Shortcode processor to process wordpress videos shortcodes to html video element
    /// More info here: https://codex.wordpress.org/Video_Shortcode
    ///
    static public var wordPressVideoPreProcessor: Processor {
        let wordPressVideoProcessor = ShortcodeProcessor(tag:"video", replacer: { (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.named["src"] {
                html += "src=\"\(src)\" "
            }
            if let poster = shortcode.attributes.named["poster"] {
                html += "poster=\"\(poster)\" "
            }
            html += "/>"
            return html
        })
        return wordPressVideoProcessor
    }

    /// Shortcode processor to process html video elements to wordpress videos shortcodes
    /// More info here: https://codex.wordpress.org/Video_Shortcode
    ///
    static public var wordPressVideoPostProcessor: Processor {
        let postWordPressVideoProcessor = HTMLProcessor(tag:"video", replacer: { (shortcode) in
            var html = "[video "
            if let src = shortcode.attributes.named["src"] {
                html += "src=\"\(src)\" "
            }
            if let poster = shortcode.attributes.named["poster"] {
                html += "poster=\"\(poster)\" "
            }
            html += "]"
            return html
        })
        return postWordPressVideoProcessor
    }
}
