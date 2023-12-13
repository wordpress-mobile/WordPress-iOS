import Foundation
import WordPressKit

final class DashboardServiceRemoteFake: DashboardServiceRemote {

    override func fetch(cards: [String], forBlogID blogID: Int, success: @escaping (NSDictionary) -> Void, failure: @escaping (Error) -> Void) {
        let bundle = Bundle(for: Self.self)

        guard let filePath = bundle.url(forResource: "dashboard_cards_data", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: filePath)
            let json = try JSONSerialization.jsonObject(with: data) as! NSDictionary
            success(json)
        } catch let error {
            failure(error)
        }
    }
}
