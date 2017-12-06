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
    case ready([TimeZoneInfo], String?, NSNumber?, ((_ timezoneString: String, _ manualOffset: NSNumber?) -> Void)?)
    case error(String)

    /// the first param is a list of all groups, used as section headers
    /// the second param is a mapping from group to timezones in that group
    typealias GroupsAndTimezones = ([String], [String: [(String, String)]])

    static let manualOffsetSectionName: String = "Manual Offsets"
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
        case .ready(let timezoneInfoArray, let usersTimezoneString, let usersManualOffset, let onChange):
            let (groups, groupToTimezones) = setupVariables(with: timezoneInfoArray)
            let indexPathToHighlight = getIndexPathToHighlight(timezoneString: usersTimezoneString, manualOffset: usersManualOffset, data: (groups, groupToTimezones), allTimezones: timezoneInfoArray)
            var sections: [ImmuTableSection] = []
            for (sectionIndex, group) in groups.enumerated() {
                guard let allTimezones = groupToTimezones[group] else {
                    continue
                }
                var rows: [CheckmarkRow] = []
                if let highlightedIndexPath = indexPathToHighlight,
                    highlightedIndexPath.section == sectionIndex {
                    for (rowIndex, timezoneInfo) in allTimezones.enumerated() {
                        let isHighlighted: Bool = rowIndex == highlightedIndexPath.row
                        let action = self.action(timeZoneValue: timezoneInfo.1, onChange: onChange)
                        rows.append(CheckmarkRow(title: timezoneInfo.0, checked: isHighlighted, action: action))
                    }
                } else {
                    rows = allTimezones.map({
                        let action = self.action(timeZoneValue: $0.1, onChange: onChange)
                        return CheckmarkRow(title: $0.0, checked: false, action: action)

                    })
                }
                let section = ImmuTableSection(headerText: group, rows: rows)
                sections.append(section)
            }
            return ImmuTable(sections: sections)
        }
    }

    // MARK: Helper methods

    private func action(timeZoneValue: String, onChange: ((_ timezoneString: String, _ manualOffset: NSNumber?) -> Void)?) -> ImmuTableAction {
        return { (row) in
            if let numberString = timeZoneValue.components(separatedBy: "UTC").last,
                let floatVal = Float(numberString) {
                let manualOffset: NSNumber = NSNumber(value: floatVal)
                onChange?("", manualOffset)
            } else {
                onChange?(timeZoneValue, nil)
            }
        }
    }

    /// Returns a sorted list of groups and timezones mapped to a group
    private func setupVariables(with result: [TimeZoneInfo]) -> GroupsAndTimezones {
        var groupNames = result.reduce(into: Set<String>(), { (mySet, timezone) in
            mySet.insert(timezone.group)
        }).sorted()

        // remove manual offset's from it's sorted position and push it to the bottom
        if let manualOffsetIndex = groupNames.index(of: TimezoneSelectorViewModel.manualOffsetSectionName) {
            groupNames.remove(at: manualOffsetIndex)
            groupNames.append(TimezoneSelectorViewModel.manualOffsetSectionName)
        }
        var timezoneNamesSortedByGroup: [String: [(String, String)]] = [:]
        for group in groupNames {
            let allTimezonesInGroup = result.filter({ $0.group == group })

            if group == TimezoneSelectorViewModel.manualOffsetSectionName {
                // sort the UTC strings
                let allLabelsAndValues = allTimezonesInGroup.map({ (label: $0.label, value: $0.value) })
                timezoneNamesSortedByGroup[group] = allLabelsAndValues.sorted(by: { (left, right) -> Bool in
                    guard let leftNumString = left.value.components(separatedBy: "UTC").last,
                        let rightNumString = right.value.components(separatedBy: "UTC").last,
                        let floatLeftNum = Float(leftNumString),
                        let floatRightNum = Float(rightNumString) else {
                            return false
                    }
                    return floatLeftNum > floatRightNum
                })
            } else {
                timezoneNamesSortedByGroup[group] = allTimezonesInGroup.sorted(by: { (timezone1, timezone2) -> Bool in
                    return timezone1.label < timezone2.label
                }).map({ ($0.label, $0.value) })
            }
        }
        return (headerNames: groupNames, sortedNamesByGroup: timezoneNamesSortedByGroup)
    }

    /// returns an IndexPath, which is the user's current selection
    private func getIndexPathToHighlight(timezoneString: String?, manualOffset: NSNumber?, data: GroupsAndTimezones, allTimezones: [TimeZoneInfo]) -> IndexPath? {
        if let usersTimeZone = timezoneString, !usersTimeZone.isEmpty {
            for (groupIndex, group) in data.0.enumerated() {
                let allTimezonesInGroup = allTimezones.filter({ $0.group == group })
                guard let keyValPair = allTimezonesInGroup.first(where: { $0.value == usersTimeZone }),
                    let index = data.1[group]?.index(where: { (labelValPair) -> Bool in
                        return labelValPair.0 == keyValPair.label
                    }) else {
                        continue
                }
                let indexPath = IndexPath(row: index, section: groupIndex)
                return indexPath
            }
        } else if let manualOffset = manualOffset,
            let section = data.0.index(of: TimezoneSelectorViewModel.manualOffsetSectionName),
            let dict = data.1[TimezoneSelectorViewModel.manualOffsetSectionName] {
            let hoursUTC = manualOffset.intValue
            let minutesUTC = abs(Int((manualOffset.doubleValue - Double(hoursUTC)) * 60))
            guard let utcString: String = TimeZoneSettingHelper.getFormattedString(prefix: "UTC", hours: hoursUTC, minutes: minutesUTC) else {
                return nil
            }
            if let index = dict.index(where: { $0.0 == utcString }) {
                let row = dict.distance(from: dict.startIndex, to: index)
                let indexPath = IndexPath(row: row, section: section)
                return indexPath
            }
        }
        return nil
    }
}
