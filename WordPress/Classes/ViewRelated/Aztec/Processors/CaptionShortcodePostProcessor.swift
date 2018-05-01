import Aztec
import Foundation


// MARK: - CaptionShortcodePostProcessor: Converts <figure><img><figcaption> structures into a [caption] shortcode.
//
class CaptionShortcodePostProcessor: HTMLProcessor {

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
            var attributes = shortcode.attributes.named
            var imgNode: ElementNode?

            // Find img child node of caption
            if coreNode.isNodeType(.img) {
                imgNode = coreNode
            } else {
                imgNode = coreNode.firstChild(ofType: .img)
            }

            if let imgNode = imgNode {
                attributes = CaptionShortcodePostProcessor.captionAttributesFrom(imgNode: imgNode, basedOn: attributes)
            }

            var attributesHTMLRepresentation: String = " id=\"\""
            if let idValue = attributes["id"] {
                attributesHTMLRepresentation = " id=\"\(idValue)\""
                attributes.removeValue(forKey: "id")
            }
            for (key, value) in attributes {
                attributesHTMLRepresentation += " \(key)=\"\(value)\""
            }

            var html = "[caption" + attributesHTMLRepresentation + "]"

            html += serializer.serialize(coreNode)

            for child in figcaption.children {
                html += serializer.serialize(child)
            }

            html += "[/caption]"

            return html
        }
    }

    static func captionAttributesFrom(imgNode: ElementNode, basedOn baseAttributes: [String: String]) -> [String: String] {
        var captionAttributes = baseAttributes
        let imgAttributes = imgNode.attributes
        for attribute in imgAttributes {
            guard attribute.name != "src",
                let attributeValue = attribute.value.toString() else {
                    continue
            }

            if attribute.name == "class" {
                let classAttributes = attributeValue.components(separatedBy: " ")
                for classAttribute in classAttributes {
                    if classAttribute.hasPrefix("wp-image-") {
                        captionAttributes["id"] = classAttribute.replacingOccurrences(of: "wp-image-", with: "attachment_")
                    } else if classAttribute.hasPrefix("align") {
                        captionAttributes["align"] = classAttribute
                    }
                }
            } else {
                captionAttributes[attribute.name] = attributeValue
            }
        }
        return captionAttributes
    }
}
