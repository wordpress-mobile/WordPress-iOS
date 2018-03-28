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
            let rootNode = HTMLParser().parse(payload)

            guard let coreNode = rootNode.firstChild(ofType: .img) ?? rootNode.firstChild(ofType: .a),
                let figcaption = rootNode.firstChild(ofType: .figcaption)
            else {
                return nil
            }

            /// Serialize the Caption's Shortcode!
            ///
            let serializer = DefaultHTMLSerializer()
            let attributes = shortcode.attributes.toString()
            let padding = attributes.isEmpty ? "" : " "

            var html = "[caption" + padding + attributes + "]"

            html += serializer.serialize(coreNode)

            for child in figcaption.children {
                html += serializer.serialize(child)
            }

            html += "[/caption]"

            return html
        }
    }
}
