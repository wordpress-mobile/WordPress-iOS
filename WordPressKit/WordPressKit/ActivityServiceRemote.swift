import Foundation
import WordPressShared
import CocoaLumberjack

public class ActivityServiceRemote: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    /// Retrieves activity events associated to a site.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - offset: The first N activities to be skipped in the returned array.
    ///     - count: Number of objects to retrieve.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: An array of activities and a boolean indicating if there's more activities to fetch.
    ///
    public func getActivityForSite(_ siteID: Int,
                                   offset: Int = 0,
                                   count: Int,
                                   success: @escaping (_ activities: [RemoteActivity], _ hasMore: Bool) -> Void,
                                   failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/activity"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug
        let pageNumber = (offset / count + 1)
        let parameters: [String: AnyObject] = [
            "locale": locale as AnyObject,
            "number": count as AnyObject,
            "page": pageNumber as AnyObject
        ]

        wordPressComRestApi.GET(path!,
                                parameters: parameters as [String : AnyObject]?,
                                success: {
                                    response, _ in
                                    do {
                                        let (activities, totalItems) = try self.mapActivitiesResponse(response)
                                        let hasMore = totalItems > pageNumber * (count + 1)
                                        success(activities, hasMore)
                                    } catch {
                                        DDLogError("Error parsing activity response for site \(siteID)")
                                        DDLogError("\(error)")
                                        DDLogDebug("Full response: \(response)")
                                        failure(error)
                                    }
        }, failure: {
            error, _ in
            failure(error)
        })
    }

}

private extension ActivityServiceRemote {

    func mapActivitiesResponse(_ response: AnyObject) throws -> ([RemoteActivity], Int) {

        guard let json = response as? [String: AnyObject],
            let totalItems = json["totalItems"] as? Int,
            let current = json["current"] as? [String: AnyObject],
            let orderedItems = current["orderedItems"] as? [[String: AnyObject]] else {
                throw ActivityServiceRemote.ResponseError.decodingFailure
        }

        let activities = try orderedItems.map { activity -> RemoteActivity in
            return try RemoteActivity(dictionary: activity)
        }

        return (activities, totalItems)
    }

}
