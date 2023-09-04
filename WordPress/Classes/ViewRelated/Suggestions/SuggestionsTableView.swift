import Foundation
import UIKit

extension SuggestionType {
    var trigger: String {
        switch self {
        case .mention: return "@"
        case .xpost: return "+"
        }
    }
}

@objc extension SuggestionsTableView: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Static Properties

    private static let nonEmptyString = "_"

    // MARK: - UITableViewDataSource & UITableViewDelegate

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.isLoading ? 1 : viewModel.sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.isLoading ? 1 : viewModel.sections[section].rows.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionsTableViewCell", for: indexPath) as! SuggestionsTableViewCell
        if viewModel.isLoading {
            cell.titleLabel.text = NSLocalizedString("Loading...", comment: "Suggestions loading message")
            cell.subtitleLabel.text = nil
            cell.iconImageView.image = nil
            cell.selectionStyle = .none
            return cell
        }

        cell.selectionStyle = .default

        let suggestion = viewModel.sections[indexPath.section].rows[indexPath.row]
        cell.titleLabel.text = suggestion.title
        cell.subtitleLabel.text = suggestion.subtitle
        cell.iconImageView.downloadImage(from: suggestion.imageURL, placeholderImage: UIImage(named: "gravatar"))

        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Ideally, we should be returning `nil` instead of `Self.nonEmptyString`.
        // But when this method returns `nil` ( or empty string ), `tableView:heightForHeaderInSection:` method doesn't get called
        // As a result, the section header is not hidden. Same behavior for section footers.
        guard !viewModel.isLoading else { return Self.nonEmptyString }
        return viewModel.sections[section].title ?? Self.nonEmptyString
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Show section header if there are more 2 sections or more.
        return viewModel.sections.count > 1 ? tableView.sectionHeaderHeight : .leastNonzeroMagnitude
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections.count > 1 ? nil : Self.nonEmptyString
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Show section footer if there are more 2 sections or more.
        return viewModel.sections.count > 1 ? tableView.sectionFooterHeight : .leastNonzeroMagnitude
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sliceIndex = viewModel.suggestionType.trigger.endIndex
        let suggestion = viewModel.item(at: indexPath)
        let searchText = String(viewModel.searchText[sliceIndex...])
        let suggestionTitle = suggestion.title == nil ? nil : String(suggestion.title![sliceIndex...])
        self.suggestionsDelegate?.suggestionsTableView?(self, didSelectSuggestion: suggestionTitle, forSearchText: searchText)
    }

    // MARK: - Layout

    /// Returns the ideal height for the table view  that displays all sections and rows as long as this height doesn't exceed the given `maximumHeight`.
    ///
    static func height(forTableView tableView: UITableView, maximumHeight height: CGFloat) -> CGFloat {
        return min(height, tableView.contentSize.height)
    }

    /// Returns the ideal height for the table view to display the given number of rows.
    ///
    static func maximumHeight(forTableView tableView: UITableView, maxNumberOfRowsToDisplay maxRows: NSNumber) -> CGFloat {
        guard let maxRowIndexPath = indexPath(forRowAtPosition: maxRows.intValue, in: tableView) else {
            return 0
        }
        let maxTableViewHeight = heightFromBeginningOfTableView(tableView, toRowAtIndexPath: maxRowIndexPath)
        return Self.height(forTableView: tableView, maximumHeight: maxTableViewHeight)
    }

    /// Returns a height from the beinning of the table view to the given row index path.
    ///
    /// This method is used to make a portion of the table view visible ( beginning to row index path ) without the need of scrolling.
    ///
    private static func heightFromBeginningOfTableView(_ tableView: UITableView, toRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        var size = CGSize(width: tableView.bounds.width, height: 0)
        let rowHeight = tableView.rowHeight
        for section in 0...indexPath.section {
            size.height += tableView.rectForHeader(inSection: section).height
            if section == indexPath.section {
                size.height += CGFloat(indexPath.row + 1) * rowHeight
                if indexPath.row == tableView.numberOfRows(inSection: section) - 1 {
                    size.height += tableView.rectForFooter(inSection: section).height
                }
            } else {
                size.height = size.height
                + CGFloat(tableView.numberOfRows(inSection: section)) * rowHeight
                + tableView.rectForFooter(inSection: section).height
            }
        }
        return size.height
    }

    /// Maps the row position to an index path.
    ///
    /// The position of a row doesn't take into account table view sections. For example:
    ///
    /// Section #1
    /// - Position 0 - IndexPath(row: 0, section: 0)
    /// - Position 1 - IndexPath(row: 1, section: 0)
    ///
    /// Section #2
    /// - Position 2 - IndexPath(row: 0, section: 1)
    /// - Position 3 - IndexPath(row: 1, section: 1)
    ///
    private static func indexPath(forRowAtPosition position: Int, in tableView: UITableView) -> IndexPath? {
        var indexPath: IndexPath?
        let numberOfSections = tableView.numberOfSections
        var remainingRows = position
        for section in 0..<numberOfSections {
            guard remainingRows > 0 else { break }
            let numberOfRows = tableView.numberOfRows(inSection: section)
            let maxRow = min(remainingRows, numberOfRows)
            indexPath = IndexPath(row: maxRow - 1, section: section)
            remainingRows -= maxRow
        }
        return indexPath
    }

    // MARK: - API

    /// Returns the a list of prominent suggestions excluding the current user.
    static func prominentSuggestions(fromPostAuthorId postAuthorId: NSNumber?, commentAuthorId: NSNumber?, defaultAccountId: NSNumber?) -> [NSNumber] {
        return [postAuthorId, commentAuthorId].compactMap { $0 != defaultAccountId ? $0 : nil }
    }
}
