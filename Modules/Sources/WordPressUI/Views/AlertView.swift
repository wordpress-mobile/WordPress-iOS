import SwiftUI
import WordPressShared

public struct AlertView<Header: View, Content: View, Actions: View>: View {
    @ViewBuilder var header: () -> Header
    @ViewBuilder let content: () -> Content
    @ViewBuilder var actions: () -> Actions

    public init(
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.header = header
        self.content = content
        self.actions = actions
    }

    public var body: some View {
        VStack(spacing: 0) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            header()
                .padding(.horizontal, 8)
                .padding(.bottom, 32)
            VStack(spacing: 16) {
                actions()
            }
        }
        .padding(24)
    }
}

extension AlertView {
    public func present(in presentingViewController: UIViewController) {
        let hostVC = UIHostingController(rootView: self)
        hostVC.sheetPresentationController?.detents = [.medium()]
        presentingViewController.present(hostVC, animated: true)
    }
}

extension AlertView where Header == AlertHeaderView, Content == Image, Actions == EmptyView {
    public init(_ title: String, image imageName: String, description: String) {
        self.init {
            AlertHeaderView(title: title, description: description)
        } content: {
            Image(imageName)
        } actions: {
            EmptyView()
        }
    }

    public init(_ title: String, systemImage name: String, description: String) {
        self.init {
            AlertHeaderView(title: title, description: description)
        } content: {
            Image(systemName: name)
        } actions: {
            EmptyView()
        }
    }
}

public struct AlertHeaderView: View {
    let title: String
    let description: String

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.medium))
            Text(description)
                .foregroundStyle(.secondary)
        }
    }
}

public struct AlertDismissButton: View {
    @Environment(\.dismiss) var dismiss

    public init() {}

    public var body: some View {
        Button {
            dismiss()
        } label: {
            Text(AppLocalizedString("shared.button.ok", value: "OK", comment: "A shared button title used in different contexts"))
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
    }
}

#Preview {
    PreviewAlertViewController()
}

private final class PreviewAlertViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(primaryAction: UIAction(title: "Show") { [weak self] _ in
            self?.showAlertView()
        })
        view.addSubview(button)
        button.pinCenter()
    }

    private func showAlertView() {
        let alert = AlertView {
            AlertHeaderView(title: "Post Saved", description: "Save this post, and come back to read it whenever you'd like. It will only be available on this device — saved posts don't sync to other devices.")
        } content: {
            ScaledImage("icon-bookmark", bundle: .module, height: 78)
                .foregroundStyle(.secondary)
        } actions: {
            AlertDismissButton()
        }
        alert.present(in: self)
    }
}
