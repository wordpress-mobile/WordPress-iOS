import UIKit

@testable import WordPress

/// Answers `refuseSignInIfRestricted(from:)` from a queue of scripted responses, then `false`.
@MainActor
final class AgeRequirementAccessControllerFake: AgeRequirementAccessControlling {
    private var refusalResponses: [Bool]
    private(set) var refusalCount = 0

    init(refusalResponses: [Bool]) {
        self.refusalResponses = refusalResponses
    }

    func refuseSignInIfRestricted(from viewController: UIViewController) -> Bool {
        refusalCount += 1
        return refusalResponses.isEmpty ? false : refusalResponses.removeFirst()
    }
}
