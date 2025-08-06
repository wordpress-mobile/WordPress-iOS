import UIKit
import SwiftUI
import WordPressUI
import WordPressKit

final class SubscribersViewController: UIHostingController<AnyView> {
    private let viewModel: SubscribersViewModel

    init(blog: SubscribersBlog) {
        self.viewModel = SubscribersViewModel(blog: blog)
        super.init(rootView: AnyView(SubscribersView(viewModel: viewModel)))
        self.title = Strings.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct SubscribersView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        Group {
            if !viewModel.searchText.isEmpty {
                SubscribersSearchView(viewModel: viewModel)
            } else {
                SubscribersListView(viewModel: viewModel)
            }
        }
        .environment(\.defaultMinListRowHeight, 50)
        .searchable(text: $viewModel.searchText)
    }
}

private struct SubscribersListView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    @State private var isShowingInviteView = false

    var body: some View {
        List {
            if let response = viewModel.response {
                SubscribersPaginatedForEach(response: response)
            }
        }
        .listStyle(.plain)
        .overlay {
            if let response = viewModel.response {
                if response.isEmpty {
                    EmptyStateView(Strings.empty, systemImage: "envelope")
                }
            } else if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                EmptyStateView.failure(error: error) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: viewModel.parameters) { _ in
            viewModel.onRefreshNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isShowingInviteView = true
                } label: {
                    Image(systemName: "plus")
                }
                SubscribersFiltersMenu(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isShowingInviteView) {
            NavigationView {
                SubscriberInviteView(blog: viewModel.blog)
            }
        }
    }
}

private struct SubscribersSearchView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        DataViewSearchView(
            searchText: viewModel.searchText,
            search: viewModel.search
        ) { response in
            SubscribersPaginatedForEach(response: response)
        }
    }
}

private struct SubscribersPaginatedForEach: View {
    @ObservedObject var response: SubscribersPaginatedResponse

    var body: some View {
        DataViewPaginatedForEach(response: response, content: makeRow)
            .onReceive(NotificationCenter.default.publisher(for: .subscriberDeleted)) { notification in
                subscriberDeleted(userInfo: notification.userInfo)
            }
    }

    private func makeRow(with item: SubscriberRowViewModel) -> some View {
        SubscriberRowView(viewModel: item)
            .onAppear { response.onRowAppeared(item) }
            .background {
                NavigationLink {
                    SubscriberDetailsView(viewModel: item.makeDetailsViewModel())
                } label: {
                    EmptyView()
                }.opacity(0)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private func subscriberDeleted(userInfo: [AnyHashable: Any]?) {
        if let subscriberID = userInfo?[SubscribersServiceRemote.subscriberIDKey] as? Int {
            response.deleteItem(withID: subscriberID)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("subscribers.title", value: "Subscribers", comment: "Screen title")
    static let empty = NSLocalizedString("subscribers.empty", value: "No Subscribers", comment: "Empty state view title")
}
