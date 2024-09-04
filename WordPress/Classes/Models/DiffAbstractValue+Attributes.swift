extension DiffAbstractValue {
    var attributes: [NSAttributedString.Key: Any]? {
        switch operation {
        case .add:
            return [
                .backgroundColor: UIColor(light: AppColor.blue(.shade5), dark: AppColor.primary(.shade80)),
                .underlineStyle: NSNumber(value: 2),
                .underlineColor: UIColor(light: AppColor.primary, dark: AppColor.primary(.shade20))
            ]
        case .del:
            return [
                .backgroundColor: UIColor(light: AppColor.red(.shade5), dark: AppColor.red(.shade80)),
                .underlineStyle: NSNumber(value: 2),
                .underlineColor: UIColor(light: AppColor.error, dark: AppColor.red(.shade20)),
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
