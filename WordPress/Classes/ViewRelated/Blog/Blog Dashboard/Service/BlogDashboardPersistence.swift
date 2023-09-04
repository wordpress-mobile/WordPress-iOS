import Foundation

class BlogDashboardPersistence {
    func persist(cards: NSDictionary, for wpComID: Int) {
        do {
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = directory.appendingPathComponent(filename(for: wpComID))
            let data = try JSONSerialization.data(withJSONObject: cards, options: [])
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // In case of an error, nothing is done
        }
    }

    func getCards(for wpComID: Int) -> NSDictionary? {
        do {
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = directory.appendingPathComponent(filename(for: wpComID))
            let data = try Data(contentsOf: fileURL)
            return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
        } catch {
            return nil
        }
    }

    private func filename(for blogID: Int) -> String {
        "cards_\(blogID).json"
    }
}

extension BlogDashboardPersistence: DashboardBlazeStoreProtocol {
    func getBlazeCampaign(forBlogID blogID: Int) -> BlazeCampaign? {
        do {
            let url = try makeBlazeCampaignURL(for: blogID)
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(BlazeCampaign.self, from: data)
        } catch {
            DDLogError("Failed to retrieve blaze campaign: \(error)")
            return nil
        }
    }

    func setBlazeCampaign(_ campaign: BlazeCampaign?, forBlogID blogID: Int) {
        do {
            let url = try makeBlazeCampaignURL(for: blogID)
            if let campaign {
                try JSONEncoder().encode(campaign).write(to: url)
            } else {
                try? FileManager.default.removeItem(at: url)
            }
        } catch {
            DDLogError("Failed to store blaze campaign: \(error)")
        }
    }

    private func makeBlazeCampaignURL(for blogID: Int) throws -> URL {
        try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("recent_blaze_campaign_\(blogID).json", isDirectory: false)
    }
}
