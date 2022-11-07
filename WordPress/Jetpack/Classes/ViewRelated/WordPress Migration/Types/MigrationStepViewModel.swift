import UIKit

class MigrationStepViewModel {

    // MARK: - Properties

    let image: UIImage?
    let title: String
    let descriptions: Descriptions
    let actions: Actions

    // MARK: - Init

    init(title: String, image: UIImage?, descriptions: Descriptions, actions: Actions) {
        self.title = title
        self.image = image
        self.descriptions = descriptions
        self.actions = actions
    }

    // MARK: - Types

    struct Actions {
        let primary: Action
        let secondary: Action
    }

    struct Descriptions {
        let primary: String
        let secondary: String
    }

    struct Action {
        let title: String
        let handler: () -> Void
    }
}
