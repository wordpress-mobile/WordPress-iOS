extension DiffAbstractValue {
    var attributes: [NSAttributedString.Key: Any]? {
        switch operation {
        case .add:
            return [.backgroundColor: WPStyleGuide.extraLightBlue(),
                    .underlineStyle: NSNumber(value: 2),
                    .underlineColor: WPStyleGuide.wordPressBlue()]
        case .del:
            return [.backgroundColor: WPStyleGuide.extraLightRed(),
                    .underlineStyle: NSNumber(value: 2),
                    .underlineColor: WPStyleGuide.errorRed(),
                    .strikethroughStyle: NSNumber(value: 1),
                    .strikethroughColor: UIColor.black]
        default:
            return nil
        }
    }
}

// This should be moved to WPShared on Revisions V2
//
private extension WPStyleGuide {
    static func extraLightBlue() -> UIColor {
        return UIColor(hexString: "e7f8ff")
    }

    static func extraLightRed() -> UIColor {
        return UIColor(hexString: "fbeeee")
    }
}


extension Array where Element == DiffAbstractValue {
    func toAttributedString() -> NSAttributedString? {
        return sorted { $0.index < $1.index }
            .reduce(NSMutableAttributedString(), combine)
            .copy() as? NSAttributedString
    }


    private func combine(left: NSMutableAttributedString, with right: DiffAbstractValue) -> NSMutableAttributedString {
        guard let value = right.value else {
            return left
        }

        let attribute = NSMutableAttributedString(string: value)
        if let attributes = right.attributes {
            attribute.addAttributes(attributes, range: NSRange(location: 0, length: value.count))
        }
        left.append(attribute)
        return left
    }
}
