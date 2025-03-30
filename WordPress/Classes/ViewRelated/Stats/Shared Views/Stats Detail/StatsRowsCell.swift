import UIKit

class StatsRowsCell: StatsBaseCell {
    struct StatsTotalRowConfiguration {
        let limitRowsDisplayed: Bool
        let rowDelegate: StatsTotalRowDelegate?
        let referrerDelegate: StatsTotalRowReferrerDelegate?
        let viewMoreDelegate: ViewMoreRowDelegate?
    }

    @IBOutlet weak var rowsStackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()

        addDefaultTotalRows(toStackView: rowsStackView)
    }

     func configureTotalRows(_ dataRows: [StatsTotalRowData],
                             inStackView rowsStackView: UIStackView,
                             forType statType: StatType,
                             configuration: StatsTotalRowConfiguration) {
         if rowsStackView.arrangedSubviews.isEmpty {
             addDefaultTotalRows(toStackView: rowsStackView)
         }

        guard !dataRows.isEmpty else {
            configureForNoData(inStackView: rowsStackView, forType: statType)
            return
        }

        let numberOfRowsToAdd = calculateNumberOfRowsToAdd(from: dataRows, withConfiguration: configuration)

        rowsStackView.arrangedSubviews.enumerated().forEach { index, view in
            configure(view: view, at: index, in: dataRows, numberOfRowsToAdd: numberOfRowsToAdd, configuration: configuration)
        }
    }

    private func addDefaultTotalRows(toStackView rowsStackView: UIStackView) {
        for _ in 0..<StatsDataHelper.maxRowsToDisplay {
            let row = StatsTotalRow.loadFromNib()
            rowsStackView.addArrangedSubview(row)
        }

        let emptyRow = StatsNoDataRow.loadFromNib()
        rowsStackView.addArrangedSubview(emptyRow)

        let viewMoreRow = ViewMoreRow.loadFromNib()
        rowsStackView.addArrangedSubview(viewMoreRow)
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
