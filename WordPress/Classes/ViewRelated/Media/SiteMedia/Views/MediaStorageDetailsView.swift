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
            url: URL(string: "https://wordpress.com/add-ons/")!
                .appending(path: blog.primaryDomainAddress)
                .appending(queryItems: [.init(name: "product", value: "storage")]),
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
                    Rectangle()
                        .fill(Color(white: 0.9))
                        .frame(height: geometry.size.height)

                    if let breakdown = usage?.breakdown {
                        HStack(spacing: 0) {
                            ForEach(breakdown.items) { item in
                                Rectangle()
                                    .fill(item.category.color)
                                    .frame(width: geometry.size.width * item.percentage)
                            }
                        }
                        .frame(height: geometry.size.height)
                    } else {
                        Rectangle()
                            .fill(progressColor)
                            .frame(
                                width: geometry.size.width * min(usage?.percentage ?? 0, 1),
                                height: geometry.size.height
                            )
                    }
                }
                .clipShape(.rect(cornerRadius: 3))
            }
            .frame(height: 16)

            if let breakdown = usage?.breakdown {
                legendView(breakdown: breakdown)
            }
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

    @ViewBuilder
    private func legendView(breakdown: MediaTypeBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(breakdown.items) { item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 8, height: 8)

                    Text(item.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(item.displaySize)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(verbatim: "(\(Int(item.percentage * 100))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

private struct Usage {
    var used: Measurement<UnitInformationStorage>
    var total: Measurement<UnitInformationStorage>
    var breakdown: MediaTypeBreakdown?

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

// Known issue: when the app is in middle of its very first media library sync, unsynced items will be shown as "Other".
// Ideally, we should show a loading indicator in the `UsageView` to indicate that something is happening in the
// background and update the breakdown view as the background syncing progresses.
private struct MediaTypeBreakdown {
    struct Item: Identifiable {
        enum Category: Int, Hashable, Comparable {
            case image
            case video
            case document
            case powerpoint
            case audio
            case other

            init(mediaType: MediaType) {
                switch mediaType {
                case .image:
                    self = .image
                case .video:
                    self = .video
                case .document:
                    self = .document
                case .powerpoint:
                    self = .powerpoint
                case .audio:
                    self = .audio
                @unknown default:
                    self = .other
                }
            }

            var displayName: String {
                switch self {
                case .image:
                    return Strings.mediaTypeImage
                case .video:
                    return Strings.mediaTypeVideo
                case .document:
                    return Strings.mediaTypeDocument
                case .powerpoint:
                    return Strings.mediaTypePowerpoint
                case .audio:
                    return Strings.mediaTypeAudio
                case .other:
                    return Strings.mediaTypeOther
                }
            }

            var color: Color {
                switch self {
                case .image:
                    return Color(red: 0.0, green: 0.48, blue: 0.8)
                case .video:
                    return .purple
                case .document:
                    return .green
                case .powerpoint:
                    return .orange
                case .audio:
                    return .pink
                case .other:
                    return .gray
                }
            }

            static func < (lhs: Category, rhs: Category) -> Bool {
                return lhs.rawValue < rhs.rawValue
            }
        }

        let category: Category
        var size: Measurement<UnitInformationStorage>
        var percentage: Double

        var id: Category {
            category
        }

        var displaySize: String {
            ByteCountFormatter.string(from: size, countStyle: .binary)
        }
    }

    let items: [Item]

    init?(media: [Media], used: Double, allowed: Double) {
        precondition(allowed > 0)

        guard !media.isEmpty else {
            return nil
        }

        // First, we categorize all media items by `Category`.
        var categorized: [Item.Category: [Media]] = [:]
        var knownSizes = 0.0
        for item in media {
            var category = Item.Category(mediaType: item.mediaType)
            let size = item.actualFileSize
            if size > 0 {
                knownSizes += size
            } else {
                // Media items with `mediaType` that is not handled by the app are consider "others". In an unlikely
                // scenario where the media file size is zero, we'll consider them as "others", too. That's to avoid
                // showing a specifc type with incorrect total file size.
                category = .other
            }
            categorized[category, default: []].append(item)
        }

        // Then, we group media items into `Item` for displaying on the breakdown view.
        var items = categorized.map { (category, media) in
            let size = media.reduce(0) { $0 + $1.actualFileSize }
            return Item(category: category, size: Measurement(value: size, unit: .bytes), percentage: size / allowed)
        }

        // We need to handle the "others" category additionally. See the comments above about the "others" category.
        var otherItem: Item
        if let index = items.firstIndex(where: { $0.category == .other }) {
            otherItem = items.remove(at: index)
        } else {
            otherItem = Item(category: .other, size: Measurement(value: 0, unit: .bytes), percentage: 0)
        }

        if knownSizes < used {
            let newValue = otherItem.size.value + (used - knownSizes)
            otherItem.size = Measurement(value: newValue, unit: .bytes)
            otherItem.percentage = newValue / allowed
        }

        if otherItem.size.value > 0 {
            items.append(otherItem)
        }

        self.items = items.sorted(using: KeyPathComparator(\.category))
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
        updateActions()
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

        self.actions = actions
    }

    private func updateUsage() {
        if let used = blog.quotaSpaceUsed, let allowed = blog.quotaSpaceAllowed {
            let breakdown = calculateMediaBreakdown(used: used.doubleValue, allowed: allowed.doubleValue)
            self.usage = .init(
                used: .init(value: used.doubleValue, unit: .bytes),
                total: .init(value: allowed.doubleValue, unit: .bytes),
                breakdown: breakdown
            )
        } else {
            self.usage = nil
        }
    }

    private func calculateMediaBreakdown(used: Double, allowed: Double) -> MediaTypeBreakdown? {
        guard let context = blog.managedObjectContext else {
            return nil
        }

        guard allowed > 0 else {
            return nil
        }

        let fetchRequest = NSFetchRequest<Media>(entityName: "Media")
        fetchRequest.predicate = NSPredicate(
            format: "blog == %@ AND remoteStatusNumber == %d",
            blog,
            MediaRemoteStatus.sync.rawValue
        )

        guard let allMedia = try? context.fetch(fetchRequest) else {
            return nil
        }

        return MediaTypeBreakdown(media: allMedia, used: used, allowed: allowed)
    }
}

private extension Media {

    // Parse the `formattedSize` String as Double (in bytes).
    //
    // The 'size' returned by WP.com API is computed using `size_format` function in
    // https://github.com/WordPress/wordpress-develop/blob/6.8.3/src/wp-includes/functions.php#L468
    //
    // The implementation here may not match the php function exactly.
    // The REST API should return the file size in number. See https://linear.app/a8c/issue/AINFRA-1496
    var actualFileSize: Double {
        guard let formattedSize = formattedSize?.trimmingCharacters(in: .whitespaces),
              !formattedSize.isEmpty else {
            return 0
        }

        let components = formattedSize.split(separator: " ", maxSplits: 1)
        guard components.count == 2 else {
            return 0
        }

        let numberString = components[0].replacingOccurrences(of: ",", with: "")
        guard let value = Double(numberString) else {
            return 0
        }

        let unit = String(components[1])
        let multiplier: Double = switch unit {
        case "B": 1
        case "KB": 1024
        case "MB": 1024 * 1024
        case "GB": 1024 * 1024 * 1024
        case "TB": 1024 * 1024 * 1024 * 1024
        case "PB": 1024 * 1024 * 1024 * 1024 * 1024
        case "EB": 1024 * 1024 * 1024 * 1024 * 1024 * 1024
        case "ZB": 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024
        case "YB": 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024
        default: 0
        }

        return value * multiplier
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

    static let mediaTypeImage = NSLocalizedString(
        "mediaLibrary.storageDetails.mediaType.image",
        value: "Images",
        comment: "Label for image media type in storage breakdown"
    )

    static let mediaTypeVideo = NSLocalizedString(
        "mediaLibrary.storageDetails.mediaType.video",
        value: "Videos",
        comment: "Label for video media type in storage breakdown"
    )

    static let mediaTypeDocument = NSLocalizedString(
        "mediaLibrary.storageDetails.mediaType.document",
        value: "Documents",
        comment: "Label for document media type in storage breakdown"
    )

    static let mediaTypePowerpoint = NSLocalizedString(
        "mediaLibrary.storageDetails.mediaType.powerpoint",
        value: "Presentations",
        comment: "Label for PowerPoint/presentation media type in storage breakdown"
    )

    static let mediaTypeAudio = NSLocalizedString(
        "mediaLibrary.storageDetails.mediaType.audio",
        value: "Audio",
        comment: "Label for audio media type in storage breakdown"
    )

    static let mediaTypeOther = NSLocalizedString(
        "mediaLibrary.storageDetails.mediaType.other",
        value: "Other",
        comment: "Label for other/unknown media type in storage breakdown"
    )
}
