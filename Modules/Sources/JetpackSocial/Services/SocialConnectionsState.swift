import Foundation

public enum SocialConnectionsState: Sendable {
    case loading
    case loaded([SocialConnection])
    case failed(SocialSharingError)

    public var value: [SocialConnection]? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    public var error: SocialSharingError? {
        if case .failed(let e) = self { return e }
        return nil
    }
}
