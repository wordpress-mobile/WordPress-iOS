import UIKit

@testable import WordPress

/// Answers `refuseSignInIfRestricted(from:)` and `undoSignInIfRestricted(from:)` from queues of scripted responses,
/// then `false`.
@MainActor
final class AgeRequirementAccessControllerFake: AgeRequirementAccessControlling {
    private var refusalResponses: [Bool]
    private var undoResponses: [Bool]
    private(set) var refusalCount = 0
    private(set) var undoCount = 0

    init(refusalResponses: [Bool], undoResponses: [Bool] = []) {
        self.refusalResponses = refusalResponses
        self.undoResponses = undoResponses
    }

    func refuseSignInIfRestricted(from viewController: UIViewController) -> Bool {
        refusalCount += 1
        return refusalResponses.isEmpty ? false : refusalResponses.removeFirst()
    }

    func undoSignInIfRestricted(from viewController: UIViewController) async -> Bool {
        undoCount += 1
        return undoResponses.isEmpty ? false : undoResponses.removeFirst()
    }
}
