import Foundation

open class TimeZoneService {
    /// Fetch TimeZoneInfo Objects from Coredata, if there are none
    /// make an API call to fetch and save the data
    func fetchTimeZoneList(success: @escaping (([TimeZoneInfo]) -> Void), failure: @escaping((Error?) -> Void)) {
        let timeZoneInfoObjects = self.loadData()
        guard timeZoneInfoObjects.count == 0 else {
            success(timeZoneInfoObjects)
            return
        }
        // fetch from API
        let api = TimeZoneRemoteREST.anonymousWordPressComRestApi(withUserAgent: WPUserAgent.wordPress())!
        TimeZoneRemoteREST(wordPressComRestApi: api).fetchTimeZoneList({ (resultsArray) in
            // no weak self here, as it's deallocated if we don't keep a strong reference
            self.saveData(resultsArray)
            success(self.loadData())
            }, failure: { (error) in
                DDLogError("Error loading timezones: \(String(describing: error))")
                failure(error)
        })
    }

    /// Save API data to core data DB
    private func saveData(_ resultsArray: [TimeZoneGroupInfo]) {
        let manager = ContextManager.sharedInstance()
        let context = manager.newDerivedContext()
        context.performAndWait {
            for groupInfo in resultsArray {
                for (key, val) in groupInfo.labelsAndValues {
                    let timezoneInfo = NSEntityDescription.insertNewObject(forEntityName: "TimeZoneInfo", into: context) as! TimeZoneInfo
                    timezoneInfo.label = key
                    timezoneInfo.value = val
                    timezoneInfo.group = groupInfo.name
                }
            }
            manager.saveContextAndWait(context)
        }
    }

    private func loadData() -> [TimeZoneInfo] {
        let fetchRequest = NSFetchRequest<TimeZoneInfo>(entityName: "TimeZoneInfo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "group", ascending: true),
                                        NSSortDescriptor(key: "label", ascending: true)]
        do {
            return try ContextManager.sharedInstance().mainContext.fetch(fetchRequest)
        } catch {
            DDLogError("Error fetching timezones from core data: \(String(describing: error))")
            return []
        }
    }
}
