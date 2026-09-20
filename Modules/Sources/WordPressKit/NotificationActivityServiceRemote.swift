import Foundation
import WordPressKitObjC

/// Account-scoped remote for the in-app Notifications activity indicator.
///
/// The bell state comes from the account-wide `has_unseen_notes` flag exposed by
/// the `me` endpoint. `markSeen` reports the newest observed notification
/// timestamp so the backend can recompute that flag. Both use the authenticated
/// WordPress.com REST API supplied at construction time.
public final class NotificationActivityServiceRemote: ServiceRemoteWordPressComREST {

    /// The response was missing the expected field or reported failure.
    public struct MalformedResponseError: Error {}

    /// Fetches the account-wide "has unseen notes" flag.
    ///
    /// A missing or non-Boolean value throws rather than defaulting to `false`,
    /// so callers can preserve the last known state instead of inventing a
    /// cleared one.
    public func fetchHasUnseenNotes() async throws -> Bool {
        struct Response: Decodable {
            let hasUnseenNotes: Bool

            enum CodingKeys: String, CodingKey {
                case hasUnseenNotes = "has_unseen_notes"
            }
        }

        let path = path(forEndpoint: "me", withVersion: ._1_1)
        let response = await wordPressComRestApi.perform(
            .get,
            URLString: path,
            parameters: ["fields": "has_unseen_notes"],
            type: Response.self
        )
        return try response.get().body.hasUnseenNotes
    }

    /// Reports the newest seen notification timestamp to the backend.
    ///
    /// - Parameter timestamp: The newest notification timestamp observed by the
    ///   list. This marks notifications as *seen*, not *read*.
    public func markSeen(timestamp: String) async throws {
        struct Response: Decodable {
            let success: Bool?
        }

        let path = path(forEndpoint: "notifications/seen", withVersion: ._1_1)
        let response = await wordPressComRestApi.perform(
            .post,
            URLString: path,
            parameters: ["time": timestamp],
            type: Response.self
        )
        if try response.get().body.success == false {
            throw MalformedResponseError()
        }
    }
}
