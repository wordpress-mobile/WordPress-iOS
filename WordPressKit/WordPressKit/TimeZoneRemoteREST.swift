import Foundation

public struct TimeZoneGroupInfo {
    public let name: String
    public let labelValueDict: [String: String]
}

public class TimeZoneRemoteREST: ServiceRemoteWordPressComREST {

    /// Fetch all the TimeZone objects
    ///
    public func fetchTimeZoneList(_ success: @escaping (([TimeZoneGroupInfo]) -> Void), failure: @escaping ((NSError?) -> Void)) {

        /// Helper function used below to get a [Label: Value] Dictionary
        func getLabelValDict(from groupArray: [[String: String]]?) -> [String: String] {
            var newGroupDict: [String: String] = [:]
            groupArray?.forEach({ (labelValDict) in
                guard let labelString = labelValDict["label"],
                    let valueString = labelValDict["value"] else {
                        return
                }
                newGroupDict[labelString] = valueString
            })
            return newGroupDict
        }

        let endpoint = "timezones"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)
        wordPressComRestApi.GET(path!, parameters: nil, success: { (response, _) in
            let dict = response as? [String: AnyObject]
            let timezonesByContinentDict = dict?["timezones_by_continent"] as? [String: AnyObject]
            var resultsArray: [TimeZoneGroupInfo] = []
            timezonesByContinentDict?.keys.forEach({ (continent) in
                let groupArray = timezonesByContinentDict?[continent] as? [[String: String]]
                let groupInfo = TimeZoneGroupInfo(name: continent, labelValueDict: getLabelValDict(from: groupArray))
                resultsArray.append(groupInfo)
            })
            let manualUTCDict = dict?["manual_utc_offsets"] as? [[String: String]]
            let manualOffsetInfo = TimeZoneGroupInfo(name: "Manual Offsets", labelValueDict: getLabelValDict(from: manualUTCDict))
            resultsArray.append(manualOffsetInfo)
            // manually append a UTC section since API does not return this section
            // while the web does have a section for this
            let utcOnlyGroup = TimeZoneGroupInfo(name: "UTC", labelValueDict: ["UTC": "UTC"])
            resultsArray.append(utcOnlyGroup)
            success(resultsArray)
        }) { (error, response) in
            failure(error)
        }
    }
}
