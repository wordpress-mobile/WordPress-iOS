import Foundation

extension MigrationSuccessCell {

    @objc(configureWithViewController:)
    func configure(with viewController: UIViewController) {
        self.onTap = { [weak viewController] in
            guard let viewController else {
                return
            }
            let handler = MigrationSuccessActionHandler()
            handler.showDeleteWordPressOverlay(with: viewController)
        }
    }
}
