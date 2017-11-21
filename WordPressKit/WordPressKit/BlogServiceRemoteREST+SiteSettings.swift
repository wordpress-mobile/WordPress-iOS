import Foundation

extension BlogServiceRemoteREST {

    public func fetchTimeZoneList(success: @escaping ([String: [String: String]]) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "timezones"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRestApi.GET(path!, parameters: nil, success: { (response, _) in
            let dict = response as? [String: AnyObject]
            let timezonesByContinentDict = dict?["timezones_by_continent"] as? [String: AnyObject]
            var resultsDict: [String: [String: String]] = [:]
            timezonesByContinentDict?.keys.forEach({ (continent) in
                var newContinentDict: [String: String] = [:]
                let continentArray = timezonesByContinentDict?[continent] as? [[String: String]]
                continentArray?.forEach({ (labelValDict) in
                    guard let labelString = labelValDict["label"],
                        let valueString = labelValDict["value"] else {
                            return
                    }
                    newContinentDict[labelString] = valueString
                })
                resultsDict[continent] = newContinentDict
            })
            let manualUTCDict = dict?["manual_utc_offsets"] as? [[String: String]]
            var manualUTCModifiedDict: [String: String] = [:]
            manualUTCDict?.forEach({ (manualOffsetDict) in
                guard let labelString = manualOffsetDict["label"],
                    let valueString = manualOffsetDict["value"] else {
                        return
                }
                manualUTCModifiedDict[labelString] = valueString
            })
            resultsDict["Manual Offsets"] = manualUTCModifiedDict
            // manually append a UTC section since API does not return this section
            // while the web does have a section for this
            resultsDict["UTC"] = ["UTC": "UTC"]
            success(resultsDict)
        }) { (error, response) in
            failure(error)
        }
    }
}
