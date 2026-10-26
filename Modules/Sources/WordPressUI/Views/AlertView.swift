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
                // Give the text the height it needs before the image takes the rest. Otherwise
                // the two split the spare height, and the text is cut off on a short screen.
                .layoutPriority(1)
            VStack(spacing: 16) {
                actions()
            }
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        .padding(24)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

extension AlertView {
    public func present(in presentingViewController: UIViewController) {
        let hostVC = UIHostingController(rootView: self)
        hostVC.sheetPresentationController?.detents = [.alertView(hostedBy: hostVC)]
        presentingViewController.present(hostVC, animated: true)
    }
}

extension UISheetPresentationController.Detent {
    /// The height for a sheet that shows an ``AlertView``: half the screen, or taller when the
    /// alert needs more room, such as on the iPhone Duo's outer screen or with a large text size.
    @MainActor
    public static func alertView<Content: View>(
        hostedBy hostVC: UIHostingController<Content>
    ) -> UISheetPresentationController.Detent {
        let cache = AlertViewHeightCache()
        return .custom(identifier: .medium) { [weak hostVC] context in
            let halfHeight = context.maximumDetentValue / 2
            let medium = UISheetPresentationController.Detent.medium().resolvedValue(in: context) ?? halfHeight
            guard let hostVC else { return medium }
            // The sheet's width is only known once it has been laid out.
            let width = hostVC.view.bounds.inset(by: hostVC.view.safeAreaInsets).width
            guard width > 0 else { return medium }
            let sizeCategory = context.containerTraitCollection.preferredContentSizeCategory
            let height = cache.height(width: width, sizeCategory: sizeCategory) {
                // Measure with a separate controller, because one on screen adds its safe area to the result.
                UIHostingController(rootView: hostVC.rootView)
                    .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
                    .height
            }
            return min(max(medium, height), context.maximumDetentValue)
        }
    }
}

/// UIKit resolves a custom detent on every frame while the sheet is dragged, so keep the last
/// measurement and measure again only when the width or the text size changes.
@MainActor
private final class AlertViewHeightCache {
    private var key: (width: CGFloat, sizeCategory: UIContentSizeCategory)?
    private var height: CGFloat = 0

    func height(width: CGFloat, sizeCategory: UIContentSizeCategory, measure: () -> CGFloat) -> CGFloat {
        if let key, key.width == width, key.sizeCategory == sizeCategory {
            return height
        }
        height = measure()
        key = (width, sizeCategory)
        return height
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

/// A standard large "OK" button that dismissed the alert.
public struct AlertDismissButton: View {
    @Environment(\.dismiss) var dismiss

    var onDismiss: (() -> Void)?

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Button {
            dismiss()
            onDismiss?()
        } label: {
            Text(AppLocalizedString("shared.button.ok", value: "OK", comment: "A shared button title used in different contexts"))
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 8))
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
