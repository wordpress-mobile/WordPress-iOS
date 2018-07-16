@testable import WordPress

final class MockActionableObject: ActionableObject {
    var textOverride: String?

    var notificationID: String? {
        return "mockID"
    }

    var metaSiteID: NSNumber? {
        return NSNumber(value: 0)
    }

    var metaCommentID: NSNumber? {
        return NSNumber(value: 0)
    }

    var isCommentApproved: Bool {
        return true
    }

    var text: String? {
        return "Hello"
    }

    func action(id: Identifier) -> FormattableContentAction? {
        return nil
    }
}

func mockActionContext() -> ActionContext {
    return ActionContext(block: MockActionableObject())
}
