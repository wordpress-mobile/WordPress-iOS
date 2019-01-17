import Foundation

extension UITableViewCell {

    func addRows(_ dataRows: [StatsTotalRowData],
                 toStackView rowsStackView: UIStackView,
                 limitRowsDisplayed: Bool = true,
                 rowDelegate: StatsTotalRowDelegate? = nil) {

        let numberOfDataRows = dataRows.count

        guard numberOfDataRows > 0 else {
            let row = StatsNoDataRow.loadFromNib()
            rowsStackView.addArrangedSubview(row)
            return
        }

        let maxRows = maxRowsToDisplay()

        let numberOfRowsToAdd: Int = {
            if limitRowsDisplayed {
                return numberOfDataRows > maxRows ? maxRows : numberOfDataRows
            }

            return numberOfDataRows
        }()

        for index in 0..<numberOfRowsToAdd {
            let dataRow = dataRows[index]
            let row = StatsTotalRow.loadFromNib()
            row.configure(rowData: dataRow, delegate: rowDelegate)

            // Don't show the separator line on the last row.
            if index == (numberOfRowsToAdd - 1) {
                row.showSeparator = false
            }

            rowsStackView.addArrangedSubview(row)
        }

        // If there are more data rows, show 'View more'.
        if limitRowsDisplayed && numberOfDataRows > maxRows {
            addViewMoreToStackView(rowsStackView)
        }
    }

    func removeRowsFromStackView(_ rowsStackView: UIStackView) {
        rowsStackView.arrangedSubviews.forEach {
            rowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    func addViewMoreToStackView(_ rowsStackView: UIStackView) {
        let row = ViewMoreRow.loadFromNib()
        rowsStackView.addArrangedSubview(row)
    }

    func maxRowsToDisplay() -> Int {
        return 6
    }

}
