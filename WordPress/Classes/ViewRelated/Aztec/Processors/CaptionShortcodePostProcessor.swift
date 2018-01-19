import Aztec
import Foundation


// MARK: - CaptionShortcodePostProcessor: Converts <figure><img><figcaption> structures into a [caption] shortcode.
//
class CaptionShortcodePostProcessor: Aztec.HTMLProcessor {

    init() {
        super.init(tag: StandardElementType.figure.rawValue) { shortcode in
            guard let payload = shortcode.content else {
                return nil
            }

            /// Parse the Shortcode's Payload: We expect an [IMG, Figcaption]
            ///
            let parsed = HTMLParser().parse(payload)
            guard let image = parsed.firstChild(ofType: .img),
                let figcaption = parsed.firstChild(ofType: .figcaption)
            else {
                return nil
            }

            /// Serialize the Caption's Shortcode!
            ///
            let serializer = DefaultHTMLSerializer()
            let attributes = shortcode.attributes.toString()
            let padding = attributes.isEmpty ? "" : " "

            var html = "[caption" + padding + attributes + "]"

            html += serializer.serialize(image)

            for child in figcaption.children {
                html += serializer.serialize(child)
            }

            html += "[/caption]"
            
            return html
        }
    }
}
