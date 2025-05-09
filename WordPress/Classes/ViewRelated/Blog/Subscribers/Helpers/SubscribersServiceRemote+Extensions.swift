import WordPressKit

extension SubscribersServiceRemote.GetSubscribersParameters.FilterSubscriptionType {
    var localizedTitle: String {
        switch self {
        case .email:
            NSLocalizedString("subscribers.filterByEmailSubscriptionType.email", value: "Subscribed", comment: "Email subscription type filter")
        case .reader:
            NSLocalizedString("subscribers.filterByEmailSubscriptionType.reader", value: "Not Subscribed", comment: "Email subscription type filter")
        case .unconfirmed:
            NSLocalizedString("subscribers.filterByEmailSubscriptionType.unconfirmed", value: "Not Confirmed", comment: "Email subscription type filter")
        case .blocked:
            NSLocalizedString("subscribers.filterByEmailSubscriptionType.blocked", value: "Not Sending", comment: "Email subscription type filter")
        }
    }
}

extension SubscribersServiceRemote.GetSubscribersParameters.FilterPaymentType {
    var localizedTitle: String {
        switch self {
        case .free:
            NSLocalizedString("subscribers.filterBySubscriptionType.free", value: "Free", comment: "Subscription type filter")
        case .paid:
            NSLocalizedString("subscribers.filterBySubscriptionType.paid", value: "Paid", comment: "Subscription type filter")
        }
    }
}

extension SubscribersServiceRemote.GetSubscribersParameters.SortField {
    var localizedTitle: String {
        switch self {
        case .dateSubscribed:
            NSLocalizedString("subscribers.sortField.dateSubscribed", value: "Date Subscribed", comment: "Subscribers sort by field")
        case .email:
            NSLocalizedString("subscribers.sortField.email", value: "Email", comment: "Subscribers sort by field")
        case .name:
            NSLocalizedString("subscribers.sortField.name", value: "Name", comment: "Subscribers sort by field")
        case .plan:
            NSLocalizedString("subscribers.sortField.plan", value: "Plan", comment: "Subscribers sort by field")
        case .subscriptionStatus:
            NSLocalizedString("subscribers.sortField.subscriptionStatus", value: "Email Subscription", comment: "Subscribers sort by field")
        }
    }
}

extension SubscribersServiceRemote.GetSubscribersParameters.SortOrder {
    var localizedTitle: String {
        switch self {
        case .ascending: SharedStrings.Misc.ascending
        case .descending: SharedStrings.Misc.descending
        }
    }
}
