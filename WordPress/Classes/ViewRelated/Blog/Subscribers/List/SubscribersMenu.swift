import SwiftUI

struct SubscribersMenu: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        Menu {
            Section {
                sorting
                filterByEmailSubscriptionType
                filterByPaymenetType
            }
            if let response = viewModel.response {
                Text("\(Strings.subscribers) \(viewModel.makeFormattedSubscribersCount(for: response))")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var sorting: some View {
        Menu {
            Section {
                Picker("", selection: viewModel.makeSortFieldBinding()) {
                    ForEach([SortField.dateSubscribed, .email, .name], id: \.self) { item in
                        Text(item.localizedTitle).tag(item)
                    }
                }
                .pickerStyle(.inline)
            }
            Section {
                Picker("", selection: viewModel.makeSortOrderBinding()) {
                    ForEach([SortOrder.descending, .ascending], id: \.self) { item in
                        Text(item.localizedTitle).tag(item)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Button(action: {}, label: {
                Text(SharedStrings.Misc.sortBy)
                Text(viewModel.makeSortFieldBinding().wrappedValue.localizedTitle)
                Image(systemName: "arrow.up.arrow.down")
            })
        }
    }

    private var filterByEmailSubscriptionType: some View {
        Picker(selection: $viewModel.parameters.subscriptionTypeFilter) {
            Text(Strings.showAll).tag(Optional<FilterSubscriptionType>.none)
            ForEach(FilterSubscriptionType.allCases, id: \.self) { item in
                Text(item.localizedTitle).tag(item)
            }
        } label: {
            Button(action: {}, label: {
                Text(Strings.filterByEmailSubscription)
                Text(viewModel.parameters.subscriptionTypeFilter?.localizedTitle ?? Strings.showAll)
                Image(systemName: "envelope")
            })
        }
        .pickerStyle(.menu)
    }

    private var filterByPaymenetType: some View {
        Picker(selection: $viewModel.parameters.paymentTypeFilter) {
            Text(Strings.showAll).tag(Optional<FilterPaymentType>.none)
            ForEach(FilterPaymentType.allCases, id: \.self) { item in
                Text(item.localizedTitle).tag(item)
            }
        } label: {
            Button(action: {}, label: {
                Text(Strings.filterByPaymentType)
                Text(viewModel.parameters.paymentTypeFilter?.localizedTitle ?? Strings.showAll)
                Image(systemName: "line.3.horizontal.decrease")
            })
        }
        .pickerStyle(.menu)
    }
}

private typealias SortField = SubscribersServiceRemote.GetSubscribersParameters.SortField
private typealias SortOrder = SubscribersServiceRemote.GetSubscribersParameters.SortOrder
private typealias FilterSubscriptionType = SubscribersServiceRemote.GetSubscribersParameters.FilterSubscriptionType
private typealias FilterPaymentType = SubscribersServiceRemote.GetSubscribersParameters.FilterPaymentType

private extension SubscribersViewModel {
    // Converts it to a non-optional.
    func makeSortFieldBinding() -> Binding<SortField> {
        Binding {
            self.parameters.sortField ?? .dateSubscribed
        } set: { value, _ in
            self.parameters.sortField = value
        }
    }

    // Converts it to a non-optional.
    func makeSortOrderBinding() -> Binding<SortOrder> {
        Binding {
            self.parameters.sortOrder ?? .descending
        } set: { value, _ in
            self.parameters.sortOrder = value
        }
    }
}

private enum Strings {
    static let filterByEmailSubscription = NSLocalizedString("subscribers.filter.emailSubscription", value: "Email Subscription", comment: "Empty state view title")
    static let filterByPaymentType = NSLocalizedString("subscribers.filter.paymentType", value: "Payment", comment: "Empty state view title")
    static let showAll = SharedStrings.Misc.default(value: SharedStrings.Misc.showAll)
    static let subscribers = NSLocalizedString("subscribers.menu.subscribers", value: "Subscribers:", comment: "Part of the label in the menu showing how many subscribers are displayed")
}
