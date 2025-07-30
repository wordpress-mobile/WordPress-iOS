import SwiftUI
import WordPressUI
import DesignSystem

struct ReferrerStatsView: View {
    let referrer: TopListItem.Referrer
    let dateRange: StatsDateRange

    private let imageSize: CGFloat = 28

    @Environment(\.context) private var context
    @Environment(\.router) private var router
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isMarkingAsSpam = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isMarkedAsSpam = false

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                headerCard
                    .dynamicTypeSize(...DynamicTypeSize.xLarge)
                if !referrer.children.isEmpty {
                    childrenCard
                }
            }
            .padding(.vertical, Constants.step1)
            .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            .frame(maxWidth: horizontalSizeClass == .regular ? Constants.maxHortizontalWidth : .infinity)
            .frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .background(Constants.Colors.background)
        .onAppear {
            context.tracker?.send(.referrerStatsScreenShown)
        }
        .navigationTitle(Strings.ReferrerDetails.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(Strings.ReferrerDetails.errorAlertTitle, isPresented: $showErrorAlert) {
            Button(Strings.Buttons.ok, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "link.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.secondary.opacity(0.5))
    }

    var headerCard: some View {
        VStack(spacing: Constants.step2) {
            referrerInfoRow
            Divider()
            markAsSpamButton
        }
        .padding(Constants.step2)
        .cardStyle()
    }

    var referrerInfoRow: some View {
        HStack(spacing: Constants.step1) {
            referrerIcon
            referrerDetails
            Spacer()
            viewsCount
        }
    }

    @ViewBuilder
    var referrerIcon: some View {
        if let iconURL = referrer.iconURL {
            CachedAsyncImage(url: iconURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                placeholderIcon
            }
            .frame(width: imageSize, height: imageSize)
        } else {
            placeholderIcon
                .frame(width: imageSize, height: imageSize)
        }
    }

    var referrerDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(referrer.name)
                .font(.headline)
                .foregroundColor(.primary)

            if let domain = referrer.domain, let url = URL(string: "https://\(domain)") {
                Link(domain, destination: url)
                    .font(.subheadline)
                    .tint(Constants.Colors.blue)
            } else if let domain = referrer.domain {
                Text(domain)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    var viewsCount: some View {
        if let views = referrer.metrics.views {
            StandaloneMetricView(metric: .views, value: views)
        }
    }

    @ViewBuilder
    var markAsSpamButton: some View {
        if isMarkedAsSpam {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.subheadline)
                Text(Strings.ReferrerDetails.markedAsSpam)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
        } else if isMarkingAsSpam {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else {
            Button(role: .destructive) {
                Task {
                    await markAsSpam()
                }
            } label: {
                Label(Strings.ReferrerDetails.markAsSpam, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    var childrenCard: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            Text(Strings.ReferrerDetails.referralSources)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, Constants.step3)

            TopListItemsView(
                data: childrenChartData,
                itemLimit: referrer.children.count,
                dateRange: dateRange
            )
        }
        .padding(.vertical, Constants.step2)
        .cardStyle()
    }

    private var childrenChartData: TopListData {
        return TopListData(
            item: .referrers,
            metric: .views,
            items: referrer.children
        )
    }

    private func markAsSpam() async {
        guard let domain = referrer.domain else { return }

        isMarkingAsSpam = true

        do {
            try await context.service.toggleSpamState(for: domain, currentValue: isMarkedAsSpam)
            // Update local state to reflect the change
            isMarkedAsSpam = true
        } catch {
            errorMessage = error.localizedDescription.isEmpty ? Strings.ReferrerDetails.markAsSpamError : error.localizedDescription
            showErrorAlert = true
        }

        isMarkingAsSpam = false
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ReferrerStatsView(
            referrer: .mock,
            dateRange: Calendar.demo.makeDateRange(for: .thisYear)
        )
    }
    .navigationViewStyle(.stack)
    .tint(Constants.Colors.jetpack)
}

private extension TopListItem.Referrer {
    static let mock = TopListItem.Referrer(
        name: "Google Search",
        domain: "google.com",
        iconURL: URL(string: "https://www.google.com/favicon.ico"),
        children: [
            TopListItem.Referrer(
                name: "wordpress development tutorial",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                children: [],
                metrics: SiteMetricsSet(views: 850)
            ),
            TopListItem.Referrer(
                name: "swift programming blog",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                children: [],
                metrics: SiteMetricsSet(views: 750)
            ),
            TopListItem.Referrer(
                name: "ios app development best practices",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                children: [],
                metrics: SiteMetricsSet(views: 600)
            )
        ],
        metrics: SiteMetricsSet(views: 2200)
    )
}
