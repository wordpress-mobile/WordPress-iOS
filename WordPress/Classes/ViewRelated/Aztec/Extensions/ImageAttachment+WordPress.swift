import Foundation
import Aztec

/// ImageAttachment extension to support extra attributes needed by the WordPress app.
///
extension ImageAttachment {

    @objc var alt: String? {
        get {
            return extraAttributes["alt"]
        }
        set {
            if let nonNilValue = newValue, newValue != "" {
                extraAttributes["alt"] = nonNilValue
            } else {
                extraAttributes.removeValue(forKey: "alt")
            }
        }
    }

    var width: Int? {
        get {
            guard let stringInt = extraAttributes["width"] else {
                return nil
            }
            return Int(stringInt)
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes["width"] = "\(nonNilValue)"
            } else {
                extraAttributes.removeValue(forKey: "width")
            }
        }
    }

    var height: Int? {
        get {
            guard let stringInt = extraAttributes["height"] else {
                return nil
            }
            return Int(stringInt)
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes["height"] = "\(nonNilValue)"
            } else {
                extraAttributes.removeValue(forKey: "height")
            }
        }
    }

    var imageID: Int? {
        get {
            guard let classAttribute = extraAttributes["class"] else {
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
            if let classAttribute = extraAttributes["class"] {
                attributes = classAttribute.components(separatedBy: " ")
            }
            attributes = attributes.filter({ (value) -> Bool in
                !value.hasPrefix("wp-image-")
            })
            if let nonNilValue = newValue {
                attributes.append("wp-image-\(nonNilValue)")
            }
            if extraAttributes.isEmpty {
                extraAttributes.removeValue(forKey: "class")
            } else {
                extraAttributes["class"] = attributes.joined(separator: " ")
            }
        }
    }
}
