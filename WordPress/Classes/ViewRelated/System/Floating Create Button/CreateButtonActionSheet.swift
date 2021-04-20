protocol ActionSheetItem {
    var handler: () -> Void { get }
    func makeButton() -> ActionSheetButton
}

/// The Action Sheet containing action buttons to create new content to be displayed from the Create Button.
class CreateButtonActionSheet: ActionSheetViewController {

    enum Constants {
        static let title = NSLocalizedString("Create New", comment: "Create New header text")
    }

    init(actions: [ActionSheetItem]) {
        let buttons = actions.map { $0.makeButton() }
        super.init(headerTitle: Constants.title, buttons: buttons)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
