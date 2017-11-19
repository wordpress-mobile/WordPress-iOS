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
    var allTimezones: [TimezoneInfo] = []
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
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 45.0
        self.loadDataFromDB()
        if self.allTimezones.count == 0 {
            self.loadDataFromAPIAndSaveToDB()
        } else {
            self.setupVariables(with: self.allTimezones)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.highlightCurrentSelection()
    }

    private func loadDataFromDB() {
        let fetchRequest = NSFetchRequest<TimezoneInfo>(entityName: "TimezoneInfo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "continent", ascending: true),
                                        NSSortDescriptor(key: "label", ascending: true)]
        do {
            self.allTimezones = try ContextManager.sharedInstance().mainContext.fetch(fetchRequest)
        } catch {
            print(error)
        }
    }

    private func setupVariables(with result: [TimezoneInfo]) {
        self.continentNames = result.reduce(into: Set<String>(), { (mySet, timezone) in
            mySet.insert(timezone.continent)
        }).sorted()
        // remove manual offset's from it's sorted position and push it to the bottom
        if let manualOffsetIndex = self.continentNames.index(of: MANUAL_OFFSET) {
            self.continentNames.remove(at: manualOffsetIndex)
            self.continentNames.append(MANUAL_OFFSET)
        }
        for continent in self.continentNames {
            let allTimezonesInContinent = result.filter({ $0.continent == continent })

            if continent == self.MANUAL_OFFSET {
                // sort the UTC strings
                let allLabelsAndValues = allTimezonesInContinent.map({ (label: $0.label, value: $0.value) })
                self.timezoneNamesSortedByContinent[continent] = allLabelsAndValues.sorted(by: { (left, right) -> Bool in
                    guard let leftNumString = left.value.components(separatedBy: "UTC").last,
                        let rightNumString = right.value.components(separatedBy: "UTC").last,
                        let floatLeftNum = Float(leftNumString),
                        let floatRightNum = Float(rightNumString) else {
                            return false
                    }
                    return floatLeftNum > floatRightNum
                }).map({ $0.label })
            } else {
                let allLabels = allTimezonesInContinent.map({ $0.label })
                self.timezoneNamesSortedByContinent[continent] = allLabels.sorted()
            }
        }
    }

    private func loadDataFromAPIAndSaveToDB() {
        let remoteService = BlogJetpackSettingsServiceRemote(wordPressComRestApi: WordPressComRestApi())!
        remoteService.fetchTimeZoneList(success: { [weak self] (resultsDict) in
            self?.insertDataToDB(resultsDict: resultsDict)
            self?.loadDataFromDB()
            if let allTimezones = self?.allTimezones {
                self?.setupVariables(with: allTimezones)
            }
            self?.highlightCurrentSelection()
            }, failure: { (error) in
                print(error)
        })
    }

    private func insertDataToDB(resultsDict: [String: [String: String]]) {
        let manager = ContextManager.sharedInstance()
        let context = manager.newDerivedContext()
        context.performAndWait {
            for (continent, timezonesInContinent) in resultsDict {
                for (key, val) in timezonesInContinent {
                    let timezoneInfo = NSEntityDescription.insertNewObject(forEntityName: "TimezoneInfo", into: context) as! TimezoneInfo
                    timezoneInfo.label = key
                    timezoneInfo.value = val
                    timezoneInfo.continent = continent
                }
            }
            manager.saveContextAndWait(context)
        }
    }

    private func highlightCurrentSelection() {
        guard self.allTimezones.count != 0,
            let indexPath = self.getIndexPathToHighlight() else {
            return
        }
        self.tableView.beginUpdates()
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
        self.tableView.endUpdates()
    }

    private func getIndexPathToHighlight() -> IndexPath? {
        if let usersTimeZone = self.usersCurrentTimeZone, !usersTimeZone.isEmpty {
            for (continentIndex, continent) in self.continentNames.enumerated() {
                let allTimezonesInContinent = self.allTimezones.filter({ $0.continent == continent })
                guard let keyValPair = allTimezonesInContinent.first(where: { $0.value == usersTimeZone }),
                    let index = self.timezoneNamesSortedByContinent[continent]?.index(of: keyValPair.label) else {
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
        let sectionContinentNamesArray = self.timezoneNamesSortedByContinent[sectionName]
        return sectionContinentNamesArray?.count ?? 0
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
