import Foundation
import CoreData

enum TimezoneSelectorViewModel {
    case loading
    /**
     - Parameters
        - first param: - all TimeZoneInfo objects
        - second param: - initialTimeZoneString
        - third param: - initialManualGMTOffset
        - fourth param: - action block to be executed when user clicks on a cell
    */
    case ready([TimeZoneGroupInfo], String?, NSNumber?, ((_ timezoneString: String, _ manualOffset: NSNumber?) -> Void)?)
    case error(String)

    var noResultsViewModel: WPNoResultsView.Model? {
        switch self {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Timezones...",
                                         comment: "Text displayed while loading the activity feed for a site")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading timezones",
                                               comment: "Text displayed when there is a failure loading the timezone list"),
                    buttonTitle: NSLocalizedString("Contact support",
                                                   comment: "Button label for contacting support")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: ""),
                    message: NSLocalizedString("An active internet connection is required to view timezones", comment: "")
                )
            }
        }
    }

    var tableViewModel: ImmuTable {
        switch self {
        case .loading, .error:
            return .Empty
        case .ready(let timezoneInfoArray, let siteTimezoneString, let siteManualOffset, let onChange):
            let groupNames = timezoneInfoArray.map({ $0.name })
            /// The selected Label string used to show a checkmark in a row
            var selectedCellLabel: String?
            if let timeZoneString = siteTimezoneString, !timeZoneString.isEmpty {
                selectedCellLabel = timeZoneString
            } else if let manualOffset = siteManualOffset {
                let utcString: String = TimeZoneSettingHelper.getDecimalBasedTimeZone(from: manualOffset)
                selectedCellLabel = utcString
            }

            var sections: [ImmuTableSection] = []
            for groupName in groupNames {
                guard let allTimezones = timezoneInfoArray.first(where: { $0.name == groupName })?.labelsAndValues else {
                    continue
                }
                var rows: [CheckmarkRow] = []
                for (timeZoneDisplayLabel, timeZoneInternalValue) in allTimezones {
                    var isSelected: Bool = false
                    if let selectedCellLabelUnwrapped = selectedCellLabel {
                        isSelected = (selectedCellLabelUnwrapped == timeZoneInternalValue)
                    }
                    let action = self.action(timeZoneValue: timeZoneInternalValue, onChange: onChange)
                    rows.append(CheckmarkRow(title: timeZoneDisplayLabel, checked: isSelected, action: action))
                }
                let section = ImmuTableSection(headerText: groupName, rows: rows)
                sections.append(section)
            }
            return ImmuTable(sections: sections)
        }
    }

    // MARK: Helper methods

    private func action(timeZoneValue: String, onChange: ((_ timezoneString: String, _ manualOffset: NSNumber?) -> Void)?) -> ImmuTableAction {
        return { (row) in
            if let numberString = timeZoneValue.components(separatedBy: TimeZoneSettingHelper.UTCString).last,
                let floatVal = Float(numberString) {
                let manualOffset: NSNumber = NSNumber(value: floatVal)
                onChange?("", manualOffset)
            } else {
                onChange?(timeZoneValue, nil)
            }
        }
    }
}
