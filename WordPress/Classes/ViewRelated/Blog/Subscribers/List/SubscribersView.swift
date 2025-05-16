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
                SubscribersMenu(viewModel: viewModel)
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

    @State private var response: SubscribersPaginatedResponse?
    @State private var error: Error?

    var body: some View {
        List {
            if let response {
                SubscribersPaginatedForEach(response: response)
            } else if error == nil {
                LoadMoreFooterView(.loading)
            }
        }
        .listStyle(.plain)
        .overlay {
            if let response, response.isEmpty {
                EmptyStateView.search()
            } else if let error {
                EmptyStateView.failure(error: error)
            }
        }
        .task(id: viewModel.searchText) {
            error = nil
            do {
                try await Task.sleep(for: .milliseconds(500))
                let response = try await viewModel.search()
                guard !Task.isCancelled else { return }
                self.response = response
            } catch {
                guard !Task.isCancelled else { return }
                self.response = nil
                self.error = error
            }
        }
    }
}

private struct SubscribersPaginatedForEach: View {
    @ObservedObject var response: SubscribersPaginatedResponse

    var body: some View {
        ForEach(response.items) {
            makeRow(with: $0)
        }
        if response.isLoading {
            LoadMoreFooterView(.loading)
        } else if response.error != nil {
            LoadMoreFooterView(.failure).onRetry {
                response.loadMore()
            }
        }
    }

    private func makeRow(with item: SubscriberRowViewModel) -> some View {
        SubscriberRowView(viewModel: item)
            .onAppear { response.onRowAppear(item) }
            .background {
                NavigationLink {
                    SubscriberDetailsView(viewModel: item.makeDetailsViewModel())
                        .onDeleted { [weak response] in
                            response?.deleteSubscriber(withID: $0)
                        }
                } label: {
                    EmptyView()
                }.opacity(0)
            }
    }
}

private enum Strings {
    static let title = NSLocalizedString("subscribers.title", value: "Subscribers", comment: "Screen title")
    static let empty = NSLocalizedString("subscribers.empty", value: "No Subscribers", comment: "Empty state view title")
}
