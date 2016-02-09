import Foundation
@testable import WordPress

class MockImmuTablePresenter: ImmuTablePresenter {
    func push(controllerGenerator: ImmuTableRowControllerGenerator) -> ImmuTableAction {
        return { _ in }
    }

    func present(controllerGenerator: ImmuTableRowControllerGenerator) -> ImmuTableAction {
        return { _ in }
    }
}
