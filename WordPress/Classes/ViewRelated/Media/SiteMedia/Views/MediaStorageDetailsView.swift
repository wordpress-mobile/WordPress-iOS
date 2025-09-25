import Foundation
import SwiftUI
import SVProgressHUD
import WordPressAPI
import WordPressCore
import WordPressData

struct MediaStorageDetailsView: View {
    @State private var purchase: WebPurchase?
    @ObservedObject private var viewModel: MediaStorageDetailsViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MediaStorageDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    UsageView(usage: viewModel.usage)
                } footer: {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }

                ForEach(viewModel.actions, id: \.kind) { action in
                    actionSection(action)
                }
            }
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if #available(iOS 26.0, *) {
                        Button(role: .cancel) {
                            dismiss()
                        }
                    } else {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
            .sheet(item: $purchase) { purchase in
                WebPurchaseView(url: purchase.url, customTitle: purchase.title) { _ in
                    SVProgressHUD.showSuccess(withStatus: purchase.successMessage)

                    self.purchase = nil
                    Task {
                        await viewModel.refresh()
                    }
                }
                .preferredColorScheme(.light)
                .onDisappear {
                    self.purchase = nil
                }
            }
            .task {
                await viewModel.refresh()
            }
        }
    }

    @ViewBuilder
    private func actionSection(_ action: Action) -> some View {
        switch action.kind {
        case .cleanUp:
            ActionSection(action: action) {
                // TODO: Implement a view that shows unattached media (order by file size)
                Image(systemName: "trash")
            }
        case .buyStorage:
            ActionSection(action: action) {
                self.purchase = .storage(blog: viewModel.blog)
            }
        case .upgradePlan:
            ActionSection(action: action) {
                self.purchase = .upgradePlan(blog: viewModel.blog)
            }
        }

    }
}

private struct Action {
    enum Kind: Hashable {
        case cleanUp
        case buyStorage
        case upgradePlan
    }

    enum State: Hashable {
        case loading
        case enabled
        case disabled
    }

    var icon: String
    var title: String
    var message: String
    var kind: Kind
    var state: State
}

private struct ActionSection<Destination: View>: View {
    let icon: String
    let title: String
    let detail: String
    private let destination: (() -> Destination)?
    private let handler: (() -> Void)?

    init(action: Action, destination: @escaping () -> Destination) {
        self.icon = action.icon
        self.title = action.title
        self.detail = action.message
        self.destination = destination
        self.handler = nil
    }

    init(action: Action, handler: @escaping () -> Void) where Destination == Never {
        self.icon = action.icon
        self.title = action.title
        self.detail = action.message
        self.destination = nil
        self.handler = handler
    }

    var body: some View {
        Section {
            if let destination {
                NavigationLink(destination: destination) {
                    HStack {
                        Image(systemName: icon)

                        Text(title)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            } else {
                Button(title, systemImage: icon) {
                    self.handler?()
                }
            }

            Text(detail)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

private struct WebPurchase: Identifiable {
    var url: URL
    var title: String
    var successMessage: String

    var id: URL {
        url
    }

    static func storage(blog: Blog) -> Self {
        WebPurchase(
            url: URL(string: "https://wordpress.com/add-ons/")!.appending(path: blog.primaryDomainAddress),
            title: Strings.buyStorageTitle,
            successMessage: Strings.storageUpgradeSuccessMessage
        )
    }

    static func upgradePlan(blog: Blog) -> Self {
        WebPurchase(
            url: URL(string: "https://wordpress.com/plans/yearly/")!.appending(path: blog.primaryDomainAddress),
            title: Strings.upgradePlanTitle,
            successMessage: Strings.planUpgradeSuccessMessage
        )
    }
}

private struct UsageView: View {
    let usage: Usage?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if let usage {
                    let usageText = String.localizedStringWithFormat(
                        Strings.usageMessage,
                        usage.usedText,
                        usage.totalText
                    )
                    Text(usageText)
                        .font(.callout)
                } else {
                    ProgressView()
                    Text(Strings.calculatingUsageMessage)
                }

                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.9))
                        .frame(height: geometry.size.height)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(
                            width: geometry.size.width * min(usage?.percentage ?? 0, 1),
                            height: geometry.size.height
                        )
                }
            }
            .frame(height: 16)
        }
    }

    private var progressColor: Color {
        let percentage = usage?.percentage ?? 0
        if percentage >= 0.9 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return Color(red: 0.0, green: 0.48, blue: 0.8)
        }
    }
}

private struct Usage {
    var used: Measurement<UnitInformationStorage>
    var total: Measurement<UnitInformationStorage>

    var usedText: String {
        ByteCountFormatter.string(from: used, countStyle: .binary)
    }

    var totalText: String {
        ByteCountFormatter.string(from: total, countStyle: .binary)
    }

    var percentage: Double {
        used.converted(to: .bytes).value / total.converted(to: .bytes).value
    }
}

private struct WebPurchaseView: UIViewControllerRepresentable {
    let viewModel: CheckoutViewModel
    let customTitle: String
    let purchaseCallback: CheckoutViewController.PurchaseCallback

    init(
        url: URL,
        customTitle: String,
        purchaseCallback: @escaping CheckoutViewController.PurchaseCallback
    ) {
        self.viewModel = CheckoutViewModel(url: url)
        self.customTitle = customTitle
        self.purchaseCallback = purchaseCallback
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = CheckoutViewController(
            viewModel: viewModel,
            customTitle: customTitle,
            purchaseCallback: purchaseCallback
        )
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak viewController] _ in
                viewController?.dismiss(animated: true)
            })
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}

@MainActor
final class MediaStorageDetailsViewModel: ObservableObject {
    fileprivate let blog: Blog
    private let client: WordPressClient
    private let service: MediaServiceRemoteCoreREST
    private var unattachedCount: Int?

    @Published fileprivate private(set) var actions: [Action] = []
    @Published fileprivate private(set) var usage: Usage?
    @Published fileprivate private(set) var isLoading: Bool = false

    init(blog: Blog) throws {
        // This feature only works on WP.com sites.
        assert(blog.dotComID != nil)

        self.blog = blog
        client = try WordPressClient(site: WordPressSite(blog: blog))
        service = MediaServiceRemoteCoreREST(client: client)

        updateUsage()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Refresh media storage
        // Due to a bug in the API (https://linear.app/a8c/issue/AINFRA-1315), we can't call the
        // `BlogService.syncBlogAndAllMetadata` function.

        updateUsage()

        do {
            unattachedCount = try await service.unattachedMediaItemCount()
        } catch {
            DDLogError("Failed due to error: \(error)")
        }

        updateActions()
    }

    private var cleanUpAction: Action {
        let message: String
        let state: Action.State

        if let unattachedCount {
            if unattachedCount == 0 {
                message = Strings.cleanupAllAttachedMessage
                state = .disabled
            } else {
                message = String.localizedStringWithFormat(
                    Strings.cleanupMessage,
                    unattachedCount
                )
                state = .enabled
            }
        } else {
            message = Strings.cleanupLoadingMessage
            state = .loading
        }

        return Action(
            icon: "trash",
            title: Strings.cleanupTitle,
            message: message,
            kind: .cleanUp,
            state: state
        )
    }

    private func updateActions() {
        var actions = [
            Action(
                icon: "opticaldiscdrive",
                title: Strings.buyStorageTitle,
                message: Strings.buyStorageMessage,
                kind: .buyStorage,
                state: .enabled
            )
        ]

        if !blog.hasPaidPlan {
            actions.append(
                Action(
                    icon: "cart",
                    title: Strings.upgradePlanTitle,
                    message: Strings.upgradePlanMessage,
                    kind: .upgradePlan,
                    state: .enabled
                )
            )
        }

        let cleanUp = cleanUpAction
        if cleanUp.state == .disabled {
            actions.append(cleanUp)
        } else {
            actions.insert(cleanUp, at: 0)
        }

        self.actions = actions
    }

    private func updateUsage() {
        if let used = blog.quotaSpaceUsed, let allowed = blog.quotaSpaceAllowed {
            self.usage = .init(used: .init(value: used.doubleValue, unit: .bytes), total: .init(value: allowed.doubleValue, unit: .bytes))
        } else {
            self.usage = nil
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "mediaLibrary.storageDetails.title",
        value: "Media Library Storage",
        comment: "Title for the storage details screen"
    )

    static let usageMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.usage",
        value: "%1$@ out of %2$@ used",
        comment: "Storage usage message showing used space and total space. %1$@ is used space, %2$@ is total space."
    )

    static let cleanupTitle = NSLocalizedString(
        "mediaLibrary.storageDetails.cleanup.title",
        value: "Remove unused items",
        comment: "Title for cleanup section"
    )

    static let cleanupMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.cleanup.message",
        value: "%1$d item unattached. Remove them to free up some space.",
        comment: "Message about unattached media that can be cleaned up. %1$d is the count of unattached media."
    )

    static let buyStorageTitle = NSLocalizedString(
        "mediaLibrary.storageDetails.buyStorage.message",
        value: "Buy storage add-on",
        comment: "Message about buying storage add-on"
    )

    static let buyStorageMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.buyStorage.detail",
        value: "Make more space for high-quality photos, videos, and other media.",
        comment: "Detail message for buying storage add-on"
    )

    static let upgradePlanTitle = NSLocalizedString(
        "mediaLibrary.storageDetails.upgradePlan.message",
        value: "Upgrade plan",
        comment: "Message about upgrading plan"
    )

    static let upgradePlanMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.upgradePlan.detail",
        value: "Upgrade your plan to increase your storage space.",
        comment: "Detail message for upgrading plan"
    )

    static let cleanupAllAttachedMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.cleanup.allAttached",
        value: "All items in the Media Library are attached.",
        comment: "Message shown when all media items are attached"
    )

    static let cleanupLoadingMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.cleanup.loading",
        value: "Finding out if there are any unattached media items...",
        comment: "Message shown while loading unattached media count"
    )

    static let calculatingUsageMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.usage.calculating",
        value: "Calculating...",
        comment: "Message shown while calculating storage usage"
    )

    static let storageUpgradeSuccessMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.purchase.storage.success",
        value: "Your site Media Library storage has been increased!",
        comment: "Success message shown after purchasing storage add-on"
    )

    static let planUpgradeSuccessMessage = NSLocalizedString(
        "mediaLibrary.storageDetails.purchase.plan.success",
        value: "Your site plan has been upgraded!",
        comment: "Success message shown after upgrading plan"
    )
}
