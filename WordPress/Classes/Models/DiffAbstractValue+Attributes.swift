extension DiffAbstractValue {
    var attributes: [NSAttributedString.Key: Any]? {
        switch operation {
        case .add:
            return [.backgroundColor: UIColor.muriel(color: MurielColor(name: .blue, shade: .shade5)),
                    .underlineStyle: NSNumber(value: 2),
                    .underlineColor: UIColor.primary]
        case .del:
            return [.backgroundColor: UIColor.muriel(color: MurielColor(name: .red, shade: .shade5)),
                    .underlineStyle: NSNumber(value: 2),
                    .underlineColor: UIColor.error,
                    .strikethroughStyle: NSNumber(value: 1),
                    .strikethroughColor: UIColor.black]
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
