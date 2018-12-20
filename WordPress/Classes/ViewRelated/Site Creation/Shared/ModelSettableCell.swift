protocol ReusableCell {
    static func cellReuseIdentifier() -> String
}

extension ReusableCell {
    /**
     Returns the cell name as string, so the cell can be registered with table or collection views.
     */
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
}

protocol ModelSettableCell: ReusableCell {
    associatedtype DataType
    var model: DataType? {get set}
}
