extension DiffAbstractValue {
    var attributes: [NSAttributedString.Key: Any]? {
        switch operation {
        case .add:
            return [
                .backgroundColor: UIColor(light: AppStyleGuide.blue(.shade5), dark: AppStyleGuide.primary(.shade80)),
                .underlineStyle: NSNumber(value: 2),
                .underlineColor: UIColor(light: AppStyleGuide.primary, dark: AppStyleGuide.primary(.shade20))
            ]
        case .del:
            return [
                .backgroundColor: UIColor(light: AppStyleGuide.red(.shade5), dark: AppStyleGuide.red(.shade80)),
                .underlineStyle: NSNumber(value: 2),
                .underlineColor: UIColor(light: AppStyleGuide.error, dark: AppStyleGuide.red(.shade20)),
                .strikethroughStyle: NSNumber(value: 1),
                .strikethroughColor: UIColor.label
            ]
        default:
            return nil
        }
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
