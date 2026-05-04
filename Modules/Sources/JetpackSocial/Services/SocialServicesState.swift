import Foundation

public enum SocialServicesState: Sendable {
    case loading
    case loaded([SocialService])
    case failed(SocialSharingError)

    public var value: [SocialService]? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    public var error: SocialSharingError? {
        if case .failed(let e) = self { return e }
        return nil
    }
}
