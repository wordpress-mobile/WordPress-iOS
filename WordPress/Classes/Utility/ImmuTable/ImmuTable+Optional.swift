import Foundation

extension ImmuTableSection {
    /// Initializes a ImmuTableSection with the given rows (skipping nil ones)
    /// and optionally header and footer text.
    ///
    /// If all the rows are nil, the initializer will return a nil section
    ///
    init?(headerText: String? = nil, optionalRows: [ImmuTableRow?], footerText: String? = nil) {
        let rows = optionalRows.compactMap({ $0 })
        guard rows.count > 0 else {
            return nil
        }
        self.init(headerText: headerText, rows: rows, footerText: footerText)
    }
}

extension ImmuTable {
    /// Initializes an ImmuTable object with the given sections, skipping any nil ones.
    ///
    init(optionalSections: [ImmuTableSection?]) {
        let sections = optionalSections.compactMap({ $0 })
        self.init(sections: sections)
    }
}
