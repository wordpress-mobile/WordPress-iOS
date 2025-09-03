import Foundation

public struct StatsEmailOpensData: Decodable, Equatable {
    public let totalSends: Int?
    public let uniqueOpens: Int?
    public let totalOpens: Int?
    public let opensRate: Double?

    public init(totalSends: Int?, uniqueOpens: Int?, totalOpens: Int?, opensRate: Double?) {
        self.totalSends = totalSends
        self.uniqueOpens = uniqueOpens
        self.totalOpens = totalOpens
        self.opensRate = opensRate
    }

    private enum CodingKeys: String, CodingKey {
        case totalSends = "total_sends"
        case uniqueOpens = "unique_opens"
        case totalOpens = "total_opens"
        case opensRate = "opens_rate"
    }
}

extension StatsEmailOpensData {
    public init?(jsonDictionary: [String: AnyObject]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
            let decoder = JSONDecoder()
            self = try decoder.decode(Self.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
