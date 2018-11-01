import UIKit

/// Renders a WzardStep
final class WizardViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .red
    }

    func render(step: WizardStep) {
        let header = step.header
        let content = step.content

        addChild(header)
        addChild(content)

        let stackView = UIStackView(arrangedSubviews: [header.view, content.view])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: view.readableContentGuide.widthAnchor),
            stackView.heightAnchor.constraint(equalTo: view.readableContentGuide.heightAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.readableContentGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.readableContentGuide.centerYAnchor)
            ])

        header.didMove(toParent: self)
        content.didMove(toParent: self)
    }
}
