import Foundation

@MainActor
public protocol ApplicationTokenListDataProvider {
    func loadApplicationTokens() async throws -> [ApplicationTokenItem]
    func deleteApplicationToken(uuid: UUID) async throws
}
