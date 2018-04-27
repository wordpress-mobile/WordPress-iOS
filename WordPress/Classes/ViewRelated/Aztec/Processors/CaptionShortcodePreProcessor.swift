import Aztec
import Foundation


// MARK: - CaptionShortcodePreProcessor: Converts [caption] shortcode into a <figure><img><figcaption> structure.
//
class CaptionShortcodePreProcessor: ShortcodeProcessor {

    struct Constants {
        static let captionTag = "caption"
    }

    init() {
        super.init(tag: Constants.captionTag) { shortcode in
            guard let payloadText = shortcode.content else {
                return nil
            }

            let payloadNode = HTMLParser().parse(payloadText)
            guard let imageContainerNode = payloadNode.firstChild(ofType: .img) ?? payloadNode.firstChild(ofType: .a), payloadNode.children.count >= 2 else {
                return nil
            }

            /// Figcaption: Figure Children (minus) the image
            ///
            let captionChildren = payloadNode.children.filter { node in
                return node != imageContainerNode
            }

            let figcaptionNode = ElementNode(type: .figcaption, attributes: [], children: captionChildren)

            /// Map Shortcode Attributes into ElementNode Attributes
            ///
            let unnamed = shortcode.attributes.unamed.map { attribute in
                return Attribute(name: attribute)
            }

            let named = shortcode.attributes.named.map { attribute in
                return Attribute(name: attribute.key, value: .string(attribute.value))
            }

            let figureAttributes = named + unnamed

            /// Figure: Image + Figcaption! Woo!
            ///
            let figure = ElementNode(type: .figure, attributes: figureAttributes, children: [imageContainerNode, figcaptionNode])

            /// Final Step: Serialize back to string.
            /// This is expected to produce a `<figure><img<figcaption/></figure>` snippet.
            ///
            let serializer = DefaultHTMLSerializer()
            return serializer.serialize(figure)
        }
    }
}
