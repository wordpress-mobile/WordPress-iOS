import Foundation
import WordPressShared

public struct TimeZoneGroupInfo {
    public let name: String
    public let labelsAndValues: [(String, String)]
    public init(name: String, labelsAndValues: [(String, String)]) {
        self.name = name
        self.labelsAndValues = labelsAndValues
    }
}

public class TimeZoneRemoteREST: ServiceRemoteWordPressComREST {

    /// Fetch all the TimeZone objects
    ///
    public func fetchTimeZoneList(_ success: @escaping (([TimeZoneGroupInfo]) -> Void), failure: @escaping ((NSError?) -> Void)) {
        let endpoint = "timezones"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug
        let parameters: [String: AnyObject] = ["_locale": locale as AnyObject]
        wordPressComRestApi.GET(path!, parameters: parameters, success: { (response, _) in
            let resultsArray = self.mapResponseToGroupInfo(response)
            success(resultsArray)
        }) { (error, response) in
            failure(error)
        }
    }

    /// Helper function to get a [Label: Value] Dictionary
    private func getLabelValDict(from groupArray: [[String: String]]?) -> [(String, String)] {
        var newGroupDict: [(String, String)] = []
        groupArray?.forEach({ (labelValDict) in
            guard let labelString = labelValDict["label"],
                let valueString = labelValDict["value"] else {
                    return
            }
            newGroupDict.append((labelString, valueString))
        })
        return newGroupDict
    }

    private func mapResponseToGroupInfo(_ response: AnyObject) -> [TimeZoneGroupInfo] {
        let dict = response as? [String: Any]
        let timezonesByContinentDict = dict?["timezones_by_continent"] as? [String: Any]
        var resultsArray: [TimeZoneGroupInfo] = []
        timezonesByContinentDict?.keys.sorted().forEach({ (continent) in
            let groupArray = timezonesByContinentDict?[continent] as? [[String: String]]
            let groupInfo = TimeZoneGroupInfo(name: continent, labelsAndValues: getLabelValDict(from: groupArray))
            resultsArray.append(groupInfo)
        })
        // manually append a UTC section since API does not return this section
        // while the web does have a section for this
        let utcOnlyGroup = TimeZoneGroupInfo(name: "UTC", labelsAndValues: [("UTC", "UTC")])
        resultsArray.append(utcOnlyGroup)

        let manualUTCDict = dict?["manual_utc_offsets"] as? [[String: String]]
        let manualOffsetInfo = TimeZoneGroupInfo(name: "Manual Offsets", labelsAndValues: getLabelValDict(from: manualUTCDict))
        resultsArray.append(manualOffsetInfo)
        return resultsArray
    }
}
