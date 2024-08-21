import Foundation

public protocol ApplicationTokenListDataProvider {
    func loadApplicationTokens() async throws -> [ApplicationTokenItem]
}
