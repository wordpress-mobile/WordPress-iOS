import SwiftUI
import WordPressKit
import WordPressUI

struct SubscriberDetailsView: View {
    let viewModel: SubscriberDetailsViewModel

    @State private var details: SubscribersServiceRemote.GetSubscriberDetailsResponse?
    @State private var stats: SubscribersServiceRemote.GetSubscriberStatsResponse?

    @State private var detailsError: Error?
    @State private var statsError: Error?

    @State private var isShowingDeleteConfirmation = false
    @State private var isDeleting = false

    @Environment(\.dismiss) var dismiss

    init(viewModel: SubscriberDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                contents
            }
            .padding()
            .disabled(isDeleting)
        }
        .task {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
        .confirmationDialog(Strings.confirmDeleteTitle, isPresented: $isShowingDeleteConfirmation, actions: {
            Button(role: .destructive) {
                deleteSubscriber()
            } label: {
                Text(Strings.delete)
            }
        }, message: {
            Text(String(format: Strings.confirmDeleteMessage, details?.displayName ?? details?.emailAddress ?? ""))
        })
    }

    @ViewBuilder
    private var contents: some View {
        if let info = details ?? viewModel.subscriber {
            SubscriberDetailsHeaderView(subscriber: info)
        }
        if let detailsError {
            CardView {
                EmptyStateView.failure(error: detailsError) {
                    Task { await refresh() }
                }
            }
        } else if let details {
            if let stats {
                SubscriberStatsView(stats: stats)
            } else if statsError == nil {
                SubscriberStatsView(stats: mockStats)
                    .redacted(reason: .placeholder)
            }
            makeNewsletterSubscriptionSection(for: details)
            makeSubscriberDetailsSections(for: details)
            makeActions(for: details)
        } else {
            SubscriberStatsView(stats: mockStats)
                .redacted(reason: .placeholder)
            makeNewsletterSubscriptionSection(for: mockFreeEmailSubscriber)
                .redacted(reason: .placeholder)
            makeSubscriberDetailsSections(for: mockFreeEmailSubscriber)
                .redacted(reason: .placeholder)
        }
    }

    // MARK: Actions

    private func refresh() async {
        async let details: Void = refreshDetails()
        async let stats: Void = refreshStats()
        _ = await (details, stats)
    }

    private func refreshDetails() async {
        detailsError = nil
        do {
            details = try await viewModel.getDetails()
        } catch {
            detailsError = error
        }
    }

    private func refreshStats() async {
        statsError = nil
        do {
            stats = try await viewModel.getStats()
        } catch {
            statsError = error
        }
    }

    private func deleteSubscriber() {
        guard let details else {
            return wpAssertionFailure("action should not be available until details are loaded")
        }
        isDeleting = true
        Task {
            do {
                try await viewModel.delete(details)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                Notice(error: error).post()
                isDeleting = false
            }
        }
    }

    // MARK: Views

    private func makeNewsletterSubscriptionSection(for details: SubscribersServiceRemote.GetSubscriberDetailsResponse) -> some View {
        CardView(Strings.sectionNewsletterSubscription) {
            InfoRow(Strings.fieldSubscriptionDate, value: viewModel.formattedDateSubscribed(details.dateSubscribed))
            let plans = details.plans ?? []
            if let plan = plans.first {
                NavigationLink {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(plans, id: \.identifier, content: makePlanView)
                        }
                        .padding()
                    }
                    .navigationTitle(Strings.fieldPlan)
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    InfoRow(Strings.fieldPlan) {
                        HStack(spacing: 4) {
                            Text(plan.title)
                            Image(systemName: "chevron.forward")
                                .font(.caption2)
                        }
                        .foregroundStyle(AppColor.primary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                InfoRow(Strings.fieldPlan, value: Strings.free)
            }
        }
    }

    private func makePlanView(for plan: SubscribersServiceRemote.GetSubscriberDetailsResponse.Plan) -> some View {
        CardView {
            HStack {
                Text(plan.title)
                    .font(.headline)
                if plan.isGift {
                    Text("– \(Strings.gift)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "gift")
                        .foregroundStyle(.secondary)
                }
            }
            InfoRow(Strings.fieldPlanStatus, value: plan.status)
            if plan.renewInterval != "one-time" {
                InfoRow(Strings.fieldRenewalInterval, value: plan.renewInterval)
                InfoRow(Strings.fieldRenewalPrice, value: {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencyCode = plan.currency
                    return formatter.string(from: plan.renewalPrice as NSNumber)
                }())
            }
            InfoRow(Strings.fieldPlanStartDate, value: plan.startDate.formatted(date: .abbreviated, time: .shortened))
            InfoRow(Strings.fieldPlanEndDate, value: plan.endDate.formatted(date: .abbreviated, time: .shortened))
        }
    }

    @ViewBuilder
    private func makeSubscriberDetailsSections(for details: SubscribersServiceRemote.GetSubscriberDetailsResponse) -> some View {
        CardView(Strings.sectionSubscriberDetails) {
            InfoRow(Strings.fieldEmail) {
                if let email = details.emailAddress, let url = URL(string: "mailto://\(email)") {
                    Link(email, destination: url)
                } else {
                    Text(details.emailAddress ?? "–")
                        .foregroundStyle(.secondary)
                }
            }
            InfoRow(Strings.fieldCountry, value: details.country?.name)
            if let site = details.siteURL {
                InfoRow(Strings.fieldSite) {
                    if let siteURL = URL(string: site) {
                        Link(site, destination: siteURL)
                    } else {
                        Text(site)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func makeActions(for details: SubscribersServiceRemote.GetSubscriberDetailsResponse) -> some View {
        Button(role: .destructive) {
            isShowingDeleteConfirmation = true
        } label: {
            if isDeleting {
                ProgressView()
            } else {
                Image(systemName: "trash")
                Text(Strings.delete)
            }
        }
    }

    func mocking(
        details: SubscribersServiceRemote.GetSubscriberDetailsResponse,
        stats: SubscribersServiceRemote.GetSubscriberStatsResponse? = nil
    ) -> SubscriberDetailsView {
        var copy = self
        copy._details = .init(wrappedValue: details)
        copy._stats = .init(wrappedValue: stats)
        return copy
    }
}

private struct SubscriberStatsView: View {
    let stats: SubscribersServiceRemote.GetSubscriberStatsResponse

    var body: some View {
        CardView {
            HStack {
                SubsciberStatsRow(
                    systemImage: "envelope",
                    title: Strings.fieldEmails,
                    value: stats.formattedEmailsCount
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                SubsciberStatsRow(
                    systemImage: "envelope.open",
                    title: Strings.fieldOpened,
                    value: "\(stats.openRate)%"
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                SubsciberStatsRow(
                    systemImage: "cursorarrow.click",
                    title: Strings.fieldClicked,
                    value: "\(stats.clickRate)%"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 2).padding(.bottom, -5) // Adjust for the large font size
        }
    }
}

private struct SubsciberStatsRow: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(height: UIFont.preferredFont(forTextStyle: .footnote).pointSize)
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(value)
                .font(Font.make(.recoleta, textStyle: .title))
        }
        .lineLimit(1)
    }
}

private extension SubscribersServiceRemote.GetSubscriberStatsResponse {
    var formattedEmailsCount: String {
        emailsSent.formatted(.number.notation(.compactName))
    }

    var openRate: Int {
        guard emailsSent > 0 else { return 0 }
        let percentage = (Double(uniqueOpens) / Double(emailsSent)) * 100
        return max(0, min(Int(percentage.rounded()), 100))
    }

    var clickRate: Int {
        guard emailsSent > 0 else { return 0 }
        let percentage = (Double(uniqueClicks) / Double(emailsSent)) * 100
        return max(0, min(Int(percentage.rounded()), 100))
    }
}

private extension SubscribersServiceRemote.GetSubscriberDetailsResponse.Plan {
    var identifier: String {
        paidSubscriptionId ?? giftId.map(\.description) ?? title
    }
}

private enum Strings {
    static let sectionNewsletterSubscription = NSLocalizedString("subscriberDetails.section.newletterSubscription", value: "Newsletter Subscription", comment: "Card section title")
    static let sectionSubscriberDetails = NSLocalizedString("subscriberDetails.section.subscriberDetails", value: "Subscriber Details", comment: "Card section title")
    static let fieldSubscriptionDate = NSLocalizedString("subscriberDetails.fieldName.subscriptionDate", value: "Subscription Date", comment: "Form field name")
    static let fieldPlan = NSLocalizedString("subscriberDetails.fieldName.plan", value: "Plan", comment: "Form field name")
    static let fieldPaidUpgrade = NSLocalizedString("subscriberDetails.fieldName.paidUpgrade", value: "Paid Upgrade", comment: "Form field name")
    static let fieldPlanStatus = NSLocalizedString("subscriberDetails.fieldName.planStatus", value: "Plan Status", comment: "Form field name")
    static let fieldRenewalInterval = NSLocalizedString("subscriberDetails.fieldName.renewalInterval", value: "Renewal Interval", comment: "Form field name")
    static let fieldRenewalPrice = NSLocalizedString("subscriberDetails.fieldName.renewalPrice", value: "Renewal Price", comment: "Form field name")
    static let fieldPlanStartDate = NSLocalizedString("subscriberDetails.fieldName.planStartDate", value: "Start Date", comment: "Form field name")
    static let fieldPlanEndDate = NSLocalizedString("subscriberDetails.fieldName.planEndDate", value: "End Date", comment: "Form field name")
    static let fieldEmails = NSLocalizedString("subscriberDetails.fieldName.statsEmailCount", value: "Emails", comment: "Form field name (has to be short!)")
    static let fieldOpened = NSLocalizedString("subscriberDetails.fieldName.statsOpenedEmails", value: "Opened", comment: "Form field name (has to be short!)")
    static let fieldClicked = NSLocalizedString("subscriberDetails.fieldName.statsClickedEmails", value: "Clicked", comment: "Form field name (has to be short!)")
    static let fieldEmail = NSLocalizedString("subscriberDetails.fieldName.email", value: "Email", comment: "Form field name")
    static let fieldCountry = NSLocalizedString("subscriberDetails.fieldName.country", value: "Country", comment: "Form field name")
    static let fieldSite = NSLocalizedString("subscriberDetails.fieldName.site", value: "Site", comment: "Form field name")
    static let free = NSLocalizedString("subscriberDetails.plan.free", value: "Free", comment: "Name of a free plan")
    static let gift = NSLocalizedString("subscriberDetails.plan.gift", value: "Gift", comment: "Newsletter subscription plan type")
    static let delete = NSLocalizedString("subscriberDetails.buttonDeleteSubscriber", value: "Delete Subscriber", comment: "Button title")
    static let confirmDeleteTitle = NSLocalizedString("subscriberDetails.deleteSubscriberConfirmationDialog.title", value: "Delete the subscriber", comment: "Remove subscriber confirmation dialog title")
    static let confirmDeleteMessage = NSLocalizedString("subscriberDetails.deleteSubscriberConfirmationDialog.message", value: "Are you sure you want to remove %@? They will no longer receive new notifications from your site.", comment: "Remove subscriber confirmation dialog message; subscriber name as input.")
}

#Preview("Free Email Subscriber") {
    NavigationView {
        SubscriberDetailsView(viewModel: .mock())
            .mocking(details: mockFreeEmailSubscriber, stats: mockStats)
    }
    .tint(AppColor.primary)
}

#Preview("Paid Reader Subscriber") {
    NavigationView {
        SubscriberDetailsView(viewModel: .mock())
            .mocking(details: mockPaidSubscriber, stats: mockStats)
    }
    .tint(AppColor.primary)
}

#Preview("Loading State") {
    NavigationView {
        SubscriberDetailsView(viewModel: .init(blog: .mock(), subscriber: mockFreeEmailSubscriber))
    }
    .tint(AppColor.primary)
}

private let mockPaidSubscriber = try! makeDecoder().decode(SubscribersServiceRemote.GetSubscriberDetailsResponse.self, from: mockPaidSubscriberData)

private let mockPaidSubscriberData = """
{
    "user_id": 255064965,
    "subscription_id": 207116368,
    "email_address": "kate.bell@example.com",
    "date_subscribed": "2025-04-17T14:40:00+00:00",
    "is_email_subscriber": false,
    "subscription_status": "Subscribed",
    "avatar": "https://picsum.photos/200",
    "display_name": "Kate Bell",
    "url": "http://example.wordpress.com",
    "country": {
        "code": "US",
        "name": "United States"
    },
    "plans": [
        {
            "is_gift": false,
            "gift_id": null,
            "paid_subscription_id": "12422686",
            "status": "active",
            "title": "Newsletter Tier",
            "currency": "USD",
            "renew_interval": "1 month",
            "inactive_renew_interval": null,
            "renewal_price": 0.5,
            "start_date": "2025-01-13T18:51:55+00:00",
            "end_date": "2025-02-13T18:51:55+00:00"
        },
        {
          "is_gift": true,
          "gift_id": 31,
          "paid_subscription_id": null,
          "status": "active",
          "title": "Newsletter Tier 3",
          "currency": "USD",
          "renew_interval": "one-time",
          "inactive_renew_interval": null,
          "renewal_price": 0,
          "start_date": "2025-05-08T14:50:28+00:00",
          "end_date": "2025-06-07T14:50:28+00:00"
        }
    ]
}
""".data(using: .utf8)!

private let mockFreeEmailSubscriber = try! makeDecoder().decode(SubscribersServiceRemote.GetSubscriberDetailsResponse.self, from: mockFreeEmailSubscriberData)

private let mockFreeEmailSubscriberData = """
{
    "user_id": 0,
    "subscription_id": 349403890,
    "email_address": "john.appleseed@example.com",
    "date_subscribed": "2025-04-17T14:40:00+00:00",
    "is_email_subscriber": true,
    "subscription_status": "Subscribed",
    "display_name": "John Appleseed",
    "url": "https://example.wordpress.com",
    "country": {
        "code": "US",
        "name": "United States"
    }
}
""".data(using: .utf8)!

private let mockStats = try! makeDecoder(keyDecodingStrategy: .convertFromSnakeCase).decode(SubscribersServiceRemote.GetSubscriberStatsResponse.self, from: mockStatsData)

private let mockStatsData = """
{
    "emails_sent": 9000,
    "unique_opens": 400,
    "unique_clicks": 200,
    "blog_registration_date": "2024-12-04 16:00:32"
}
""".data(using: .utf8)!

private func makeDecoder(keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = keyDecodingStrategy
    return decoder
}
