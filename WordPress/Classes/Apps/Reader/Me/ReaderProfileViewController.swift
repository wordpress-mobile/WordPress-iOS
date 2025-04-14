import UIKit
import SwiftUI
import WordPressUI

final class ReaderProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let mySiteVC = MySiteViewController()
        mySiteVC.isReaderAppModeEnabled = true
        mySiteVC.willMove(toParent: self)
        addChild(mySiteVC)
        view.addSubview(mySiteVC.view)
        mySiteVC.view.pinEdges()
        mySiteVC.willMove(toParent: self)

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(buttonSettingsTapped))
    }

    @objc private func buttonSettingsTapped() {
        let meVC = MeViewController()
        let navigationVC = UINavigationController(rootViewController: meVC)
        meVC.navigationItem.title = nil

        meVC.navigationItem.rightBarButtonItem = {
            let button = UIBarButtonItem(title: SharedStrings.Button.done, primaryAction: .init { [weak self] _ in
                self?.dismiss(animated: true)
            })
            button.setTitleTextAttributes([.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)], for: .normal)
            return button
        }()

        if traitCollection.horizontalSizeClass == .regular {
            meVC.isSidebarModeEnabled = true
            navigationVC.modalPresentationStyle = .formSheet
        }
        present(navigationVC, animated: true)
    }
}
