import Foundation

open class TimeZoneService {
    /// Fetch TimeZoneInfo Objects from Coredata, if there are none
    /// make an API call to fetch and save the data
    func fetchTimeZoneList(success: @escaping (([TimeZoneGroupInfo]) -> Void), failure: @escaping((Error?) -> Void)) {
        // fetch from API
        let api = TimeZoneRemoteREST.anonymousWordPressComRestApi(withUserAgent: WPUserAgent.wordPress())!
        TimeZoneRemoteREST(wordPressComRestApi: api).fetchTimeZoneList({ (resultsArray) in
            // no weak self here, as it's deallocated if we don't keep a strong reference
            success(resultsArray)
            }, failure: { (error) in
                DDLogError("Error loading timezones: \(String(describing: error))")
                failure(error)
        })
    }
}
