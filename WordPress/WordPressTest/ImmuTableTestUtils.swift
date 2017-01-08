import Foundation
@testable import WordPress

class MockImmuTablePresenter: ImmuTablePresenter {
    func push(_ controllerGenerator: @escaping ImmuTableRowControllerGenerator) -> ImmuTableAction {
        return { _ in }
    }

    func present(_ controllerGenerator: @escaping ImmuTableRowControllerGenerator) -> ImmuTableAction {
        return { _ in }
    }
}
