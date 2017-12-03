import Foundation
import CoreData

/// Model for TimezoneSelectorViewController's ImmuTablePresenter
enum TimezoneSelectorViewModel {
    case loading
    /**
     - Parameters
        - first param: - all TimeZoneInfo objects
        - second param: - initialTimeZoneString
        - third param: - initialManualGMTOffset
        - fourth param: - action block to be executed when user clicks on a cell
    */
    case ready([TimeZoneInfo], String?, NSNumber?, ImmuTableAction)
    case error(String)

    /// the first param is a list of all continents, used as section headers
    /// the second param is a mapping from continent to timezones in that continent
    typealias ContinentsAndTimezones = ([String], [String: [(String, String)]])

    /// constant used in the functions below
    var MANUAL_OFFSET: String { return "Manual Offsets" }
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

    func tableViewModel() -> ImmuTable {
        switch self {
        case .loading, .error:
            return .Empty
        case .ready(let timezoneInfoArray, let usersTimezoneString, let usersManualOffset, let action):
            let (continents, continentToTimezones) = self.setupVariables(with: timezoneInfoArray)
            let indexPathToHighlight = self.getIndexPathToHighlight(timezoneString: usersTimezoneString, manualOffset: usersManualOffset, data: (continents, continentToTimezones), allTimezones: timezoneInfoArray)
            var sections: [ImmuTableSection] = []
            for (sectionIndex, continent) in continents.enumerated() {
                guard let allTimezones = continentToTimezones[continent] else {
                    continue
                }
                var rows: [TimezoneListRow] = []
                if let highlightedIndexPath = indexPathToHighlight,
                    highlightedIndexPath.section == sectionIndex {
                    for (rowIndex, timezoneInfo) in allTimezones.enumerated() {
                        let isHighlighted: Bool = rowIndex == highlightedIndexPath.row
                        rows.append(TimezoneListRow(timezoneLabel: timezoneInfo.0, timezoneValue: timezoneInfo.1, action: action, highlighted: isHighlighted))
                    }
                } else {
                    rows = allTimezones.map({ TimezoneListRow(timezoneLabel: $0.0, timezoneValue: $0.1, action: action, highlighted: false) })
                }
                let section = ImmuTableSection(headerText: continent, rows: rows)
                sections.append(section)
            }
            return ImmuTable(sections: sections)
        }
    }

    // MARK: Helper methods

    /// Save API data to core data DB
    func insertDataToDB(resultsDict: [String: [String: String]]) {
        let manager = ContextManager.sharedInstance()
        let context = manager.newDerivedContext()
        context.performAndWait {
            for (continent, timezonesInContinent) in resultsDict {
                for (key, val) in timezonesInContinent {
                    let timezoneInfo = NSEntityDescription.insertNewObject(forEntityName: "TimeZoneInfo", into: context) as! TimeZoneInfo
                    timezoneInfo.label = key
                    timezoneInfo.value = val
                    timezoneInfo.continent = continent
                }
            }
            manager.saveContextAndWait(context)
        }
    }

    /// Helper method to fetch all TimeZoneInfo objects from DB
    func loadDataFromDB() -> [TimeZoneInfo] {
        let fetchRequest = NSFetchRequest<TimeZoneInfo>(entityName: "TimeZoneInfo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "continent", ascending: true),
                                        NSSortDescriptor(key: "label", ascending: true)]
        do {
            return try ContextManager.sharedInstance().mainContext.fetch(fetchRequest)
        } catch {
            print(error)
            return []
        }
    }

    /// Returns a sorted list of continents and timezones mapped to a continent
    private func setupVariables(with result: [TimeZoneInfo]) -> ContinentsAndTimezones {
        var continentNames = result.reduce(into: Set<String>(), { (mySet, timezone) in
            mySet.insert(timezone.continent)
        }).sorted()

        // remove manual offset's from it's sorted position and push it to the bottom
        if let manualOffsetIndex = continentNames.index(of: self.MANUAL_OFFSET) {
            continentNames.remove(at: manualOffsetIndex)
            continentNames.append(self.MANUAL_OFFSET)
        }
        var timezoneNamesSortedByContinent: [String: [(String, String)]] = [:]
        for continent in continentNames {
            let allTimezonesInContinent = result.filter({ $0.continent == continent })

            if continent == self.MANUAL_OFFSET {
                // sort the UTC strings
                let allLabelsAndValues = allTimezonesInContinent.map({ (label: $0.label, value: $0.value) })
                timezoneNamesSortedByContinent[continent] = allLabelsAndValues.sorted(by: { (left, right) -> Bool in
                    guard let leftNumString = left.value.components(separatedBy: "UTC").last,
                        let rightNumString = right.value.components(separatedBy: "UTC").last,
                        let floatLeftNum = Float(leftNumString),
                        let floatRightNum = Float(rightNumString) else {
                            return false
                    }
                    return floatLeftNum > floatRightNum
                })
            } else {
                timezoneNamesSortedByContinent[continent] = allTimezonesInContinent.sorted(by: { (timezone1, timezone2) -> Bool in
                    return timezone1.label < timezone2.label
                }).map({ ($0.label, $0.value) })
            }
        }
        return (headerNames: continentNames, sortedNamesByContinent: timezoneNamesSortedByContinent)
    }

    /// returns an IndexPath, which is the user's current selection
    private func getIndexPathToHighlight(timezoneString: String?, manualOffset: NSNumber?, data: ContinentsAndTimezones, allTimezones: [TimeZoneInfo]) -> IndexPath? {
        if let usersTimeZone = timezoneString, !usersTimeZone.isEmpty {
            for (continentIndex, continent) in data.0.enumerated() {
                let allTimezonesInContinent = allTimezones.filter({ $0.continent == continent })
                guard let keyValPair = allTimezonesInContinent.first(where: { $0.value == usersTimeZone }),
                    let index = data.1[continent]?.index(where: { (labelValPair) -> Bool in
                        return labelValPair.0 == keyValPair.label
                    }) else {
                        continue
                }
                let indexPath = IndexPath(row: index, section: continentIndex)
                return indexPath
            }
        } else if let manualOffset = manualOffset,
            let section = data.0.index(of: self.MANUAL_OFFSET),
            let dict = data.1[self.MANUAL_OFFSET] {
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

/// Cell model used in TimezoneSelectorVC to display timezones
struct TimezoneListRow: ImmuTableRow {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.class(UITableViewCell.self)
    }()

    let timezoneLabel: String
    let timezoneValue: String
    let action: ImmuTableAction?
    let highlighted: Bool

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = timezoneLabel
        if highlighted {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.selectionStyle = .none
    }
}
