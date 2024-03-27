import Foundation

/// Convenience enum to easily indicate what type of rows are being added.
///
enum StatType: Int {
    case insights
    case period
}

extension UITableViewCell {

    func addRows(_ dataRows: [StatsTotalRowData],
                 toStackView rowsStackView: UIStackView,
                 forType statType: StatType,
                 limitRowsDisplayed: Bool = true,
                 rowDelegate: StatsTotalRowDelegate? = nil,
                 referrerDelegate: StatsTotalRowReferrerDelegate? = nil,
                 viewMoreDelegate: ViewMoreRowDelegate? = nil) {

        let numberOfDataRows = dataRows.count

        guard numberOfDataRows > 0 else {
            let row = StatsNoDataRow.loadFromNib()
            row.configure(forType: statType)
            rowsStackView.addArrangedSubview(row)
            return
        }

        let maxRows = StatsDataHelper.maxRowsToDisplay

        let numberOfRowsToAdd: Int = {
            if limitRowsDisplayed {
                return numberOfDataRows > maxRows ? maxRows : numberOfDataRows
            }

            return numberOfDataRows
        }()

        for index in 0..<numberOfRowsToAdd {
            let dataRow = dataRows[index]
            let row = StatsTotalRow.loadFromNib()
            row.configure(rowData: dataRow, delegate: rowDelegate, referrerDelegate: referrerDelegate)

            // Don't show the separator line on the last row.
            if index == (numberOfRowsToAdd - 1) {
                row.showSeparator = false
            }

            rowsStackView.addArrangedSubview(row)
        }

        // If there are more data rows, show 'View more'.
        if limitRowsDisplayed && numberOfDataRows > maxRows {
            addViewMoreToStackView(rowsStackView, forStatSection: dataRows.first?.statSection, withDelegate: viewMoreDelegate)
        }
    }

    func removeRowsFromStackView(_ rowsStackView: UIStackView) {
        rowsStackView.arrangedSubviews.forEach {
            rowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    func addViewMoreToStackView(_ rowsStackView: UIStackView,
                                forStatSection statSection: StatSection?,
                                withDelegate delegate: ViewMoreRowDelegate?) {
        let row = ViewMoreRow.loadFromNib()
        row.configure(statSection: statSection, delegate: delegate)
        rowsStackView.addArrangedSubview(row)
    }

}

 extension UITableViewCell {
    struct StatsTotalRowConfiguration {
        let limitRowsDisplayed: Bool
        let rowDelegate: StatsTotalRowDelegate?
        let referrerDelegate: StatsTotalRowReferrerDelegate?
        let viewMoreDelegate: ViewMoreRowDelegate?
    }

    func addDefaultTotalRows(toStackView rowsStackView: UIStackView) {
        for _ in 0..<StatsDataHelper.maxRowsToDisplay {
            let row = StatsTotalRow.loadFromNib()
            rowsStackView.addArrangedSubview(row)
        }

        let emptyRow = StatsNoDataRow.loadFromNib()
        rowsStackView.addArrangedSubview(emptyRow)

        let viewMoreRow = ViewMoreRow.loadFromNib()
        rowsStackView.addArrangedSubview(viewMoreRow)
    }

     func configureTotalRows(_ dataRows: [StatsTotalRowData],
                             inStackView rowsStackView: UIStackView,
                             forType statType: StatType,
                             configuration: StatsTotalRowConfiguration) {

        guard !dataRows.isEmpty else {
            configureForNoData(inStackView: rowsStackView, forType: statType)
            return
        }

        let numberOfRowsToAdd = calculateNumberOfRowsToAdd(from: dataRows, withConfiguration: configuration)

        rowsStackView.arrangedSubviews.enumerated().forEach { index, view in
            configure(view: view, at: index, in: dataRows, numberOfRowsToAdd: numberOfRowsToAdd, configuration: configuration)
        }
    }

    private func configureForNoData(inStackView rowsStackView: UIStackView, forType statType: StatType) {
        rowsStackView.arrangedSubviews.forEach { view in
            if let emptyRow = view as? StatsNoDataRow {
                emptyRow.isHidden = false
                emptyRow.configure(forType: statType)
            } else {
                view.isHidden = true
            }
        }
    }

     private func calculateNumberOfRowsToAdd(from dataRows: [StatsTotalRowData], withConfiguration configuration: StatsTotalRowConfiguration) -> Int {
        if configuration.limitRowsDisplayed {
            return min(dataRows.count, StatsDataHelper.maxRowsToDisplay)
        }
        return dataRows.count
    }

     private func configure(view: UIView, at index: Int, in dataRows: [StatsTotalRowData], numberOfRowsToAdd: Int, configuration: StatsTotalRowConfiguration) {
        switch view {
        case let view as StatsNoDataRow:
            view.isHidden = true
        case let view as ViewMoreRow:
            configureViewMoreRow(view, at: index, in: dataRows, withConfiguration: configuration)
        case let view as StatsTotalRow where index < dataRows.count:
            view.isHidden = false
            let dataRow = dataRows[index]
            view.configure(rowData: dataRow, delegate: configuration.rowDelegate, referrerDelegate: configuration.referrerDelegate)
            view.showSeparator = index != (numberOfRowsToAdd - 1)
        default:
            view.isHidden = true
        }
    }

     private func configureViewMoreRow(_ viewMoreRow: ViewMoreRow, at index: Int, in dataRows: [StatsTotalRowData], withConfiguration configuration: StatsTotalRowConfiguration) {
        let shouldShowViewMore = configuration.limitRowsDisplayed && dataRows.count > StatsDataHelper.maxRowsToDisplay
        viewMoreRow.isHidden = !shouldShowViewMore
        if shouldShowViewMore {
            viewMoreRow.configure(statSection: dataRows.first?.statSection, delegate: configuration.viewMoreDelegate)
        }
    }
}
