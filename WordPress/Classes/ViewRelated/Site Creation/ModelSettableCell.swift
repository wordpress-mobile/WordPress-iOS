protocol ModelSettableCell {
    associatedtype DataType
    var model: DataType? {get set}
}

/**
 Cells implementing the DataSettable protocol would also implement by default cellReuseIdentifier
 */
extension ModelSettableCell {
    /**
     Returns the cell name as string, so the cell can be registered with table or collection views.
     */
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
}
