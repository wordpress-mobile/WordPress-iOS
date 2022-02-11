import Foundation

class BlogDashboardPersistence {
    func persist(cards: NSDictionary, for wpComID: Int) {
        do {
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = directory.appendingPathComponent("cards_\(wpComID).json")
            let data = try JSONSerialization.data(withJSONObject: cards, options: [])
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // In case of an error, nothing is done
        }
    }

    func getCards(for wpComID: Int) -> NSDictionary? {
        do {
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = directory.appendingPathComponent("cards_\(wpComID).json")
            let data = try Data(contentsOf: fileURL)
            return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
        } catch {
            return nil
        }
    }
}
