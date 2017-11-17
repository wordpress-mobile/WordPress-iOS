//
//  TimeZoneSelectorViewController.swift
//  WordPress
//
//  Created by Asif on 11/11/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

class TimeZoneSelectorViewController: UITableViewController {

    /// used to show section headers
    var continentNames: [String] = []
    /// used to show text in cell sorted by continent
    var timezoneNamesSortedByContinent: [String: [String]] = [:]
    /// contains mapping of continent to (timezone label to timezone value to send to API)
    var timezoneDict: [String: [String: String]] = [:]
    /// users current timezone passed by SiteSettingsVC, if empty means manual offset is to be used
    var usersCurrentTimeZone: String?
    /// users manual offset passed by SiteSettingsVC
    var usersManualOffset: NSNumber?
    /// constant used below in string checks
    let MANUAL_OFFSET: String = "Manual Offsets"

    override init(style: UITableViewStyle) {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        let remoteService = BlogJetpackSettingsServiceRemote(wordPressComRestApi: WordPressComRestApi())!
        remoteService.fetchTimeZoneList(success: { [weak self] (resultsDict) in
            self?.setupDatasource(resultsDict: resultsDict)
            self?.highlightCurrentSelection()
        }, failure: { (error) in
            print(error)
        })
    }

    func setupDatasource(resultsDict: [String: [String: String]]) {
        self.continentNames = resultsDict.keys.sorted()
        // remove manual offset's from it's sorted position and push it to the bottom
        if let manualOffsetIndex = self.continentNames.index(of: MANUAL_OFFSET) {
            self.continentNames.remove(at: manualOffsetIndex)
            self.continentNames.append(MANUAL_OFFSET)
        }
        self.timezoneDict = resultsDict
        self.continentNames.forEach({ (continent) in
            if continent == self.MANUAL_OFFSET {
                // sort the UTC strings
                self.timezoneNamesSortedByContinent[continent] = self.timezoneDict[continent]?.keys.sorted(by: { (left, right) -> Bool in
                    guard let leftValue = self.timezoneDict[continent]?[left],
                        let rightValue = self.timezoneDict[continent]?[right],
                        let leftNumString = leftValue.components(separatedBy: "UTC").last,
                        let rightNumString = rightValue.components(separatedBy: "UTC").last,
                        let floatLeftNum = Float(leftNumString),
                        let floatRightNum = Float(rightNumString) else {
                            return false
                    }
                    return floatLeftNum > floatRightNum
                })
            } else {
                guard let sortedKeys = self.timezoneDict[continent]?.keys.sorted() else {
                    return
                }
                self.timezoneNamesSortedByContinent[continent] = sortedKeys
            }
        })
        self.tableView.reloadData()
    }

    func highlightCurrentSelection() {
        guard let indexPath = self.getIndexPathToHighlight() else {
            return
        }
        self.tableView.beginUpdates()
        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.middle)
        self.tableView.endUpdates()
    }

    func getIndexPathToHighlight() -> IndexPath? {
        if let usersTimeZone = self.usersCurrentTimeZone, !usersTimeZone.isEmpty {
            for (continentIndex, continent) in self.continentNames.enumerated() {
                guard let allTimezonesInContinent = self.timezoneDict[continent],
                    let keyValPair = allTimezonesInContinent.first(where: { $0.1 == usersTimeZone }),
                    let index = self.timezoneNamesSortedByContinent[continent]?.index(of: keyValPair.0) else {
                        continue
                }
                let indexPath = IndexPath(row: index, section: continentIndex)
                return indexPath
            }
        } else if let manualOffset = self.usersManualOffset,
            let section = self.continentNames.index(of: self.MANUAL_OFFSET),
            let dict = self.timezoneNamesSortedByContinent[MANUAL_OFFSET] {
            let hoursUTC = manualOffset.intValue
            let minutesUTC = Int((manualOffset.doubleValue - Double(hoursUTC)) * 60)
            let utcString: String
            if minutesUTC == 0 {
                utcString = String(format: "UTC%+d", hoursUTC)
            } else {
                utcString = String(format: "UTC%+d:%d", hoursUTC, minutesUTC)
            }
            if let index = dict.index(where: { $0 == utcString }) {
                let row = dict.distance(from: dict.startIndex, to: index)
                let indexPath = IndexPath(row: row, section: section)
                return indexPath
            }
        }
        return nil
    }

    // MARK:- UITableView Datasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.continentNames.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionName = self.continentNames[section]
        let sectionDict = self.timezoneDict[sectionName]
        return sectionDict?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.continentNames[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let continentName = self.continentNames[indexPath.section]
        let cellText = self.timezoneNamesSortedByContinent[continentName]?[indexPath.row]
        cell.textLabel?.text = cellText
        cell.selectionStyle = .none
        if self.tableView.indexPathForSelectedRow == indexPath {
            cell.accessoryType = .checkmark
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
