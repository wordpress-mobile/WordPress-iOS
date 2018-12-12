import Foundation
import Aztec

/// ImageAttachment extension to support extra attributes needed by the WordPress app.
///
extension ImageAttachment {

    @objc var alt: String? {
        get {
            return extraAttributes["alt"]?.toString()
        }
        set {
            if let nonNilValue = newValue, newValue != "" {
                extraAttributes["alt"] = .string(nonNilValue)
            } else {
                extraAttributes.remove(named: "alt")
            }
        }
    }

    var width: Int? {
        get {
            guard let stringInt = extraAttributes["width"]?.toString() else {
                return nil
            }
            return Int(stringInt)
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes["width"] = .string(String(nonNilValue))
            } else {
                extraAttributes.remove(named: "width")
            }
        }
    }

    var height: Int? {
        get {
            guard let stringInt = extraAttributes["height"]?.toString() else {
                return nil
            }
            return Int(stringInt)
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes["height"] = .string(String(nonNilValue))
            } else {
                extraAttributes.remove(named: "height")
            }
        }
    }

    var imageID: Int? {
        get {
            guard let classAttribute = extraAttributes["class"]?.toString() else {
                return nil
            }
            let attributes = classAttribute.components(separatedBy: " ")
            guard let imageIDAttribute = attributes.filter({ (value) -> Bool in
                value.hasPrefix("wp-image-")
            }).first else {
                return nil
            }
            let imageIDString = imageIDAttribute.removingPrefix("wp-image-")
            return Int(imageIDString)
        }
        set {
            var attributes = [String]()
            if let classAttribute = extraAttributes["class"]?.toString() {
                attributes = classAttribute.components(separatedBy: " ")
            }
            attributes = attributes.filter({ (value) -> Bool in
                !value.hasPrefix("wp-image-")
            })
            if let nonNilValue = newValue {
                attributes.append("wp-image-\(nonNilValue)")
            }
            if extraAttributes.isEmpty {
                extraAttributes.remove(named: "class")
            } else {
                extraAttributes["class"] = .string(attributes.joined(separator: " "))
            }
        }
    }
}
