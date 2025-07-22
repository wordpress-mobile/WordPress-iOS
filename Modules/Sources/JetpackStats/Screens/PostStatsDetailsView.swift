import SwiftUI
import UIKit
import WordPressKit

struct PostStatsDetailsView: View {
    let post: TopListData.Post
    
    @Environment(\.context) private var context
    @State private var details: StatsPostDetails?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step2) {
                if let details {
                    PostHeaderCard(post: post, details: details, context: context)
                        .cardStyle()
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .cardStyle()
                } else if let error {
                    SimpleErrorView(error: error)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .cardStyle()
                }
            }
            .padding(.vertical, Constants.step1)
        }
        .background(Constants.Colors.statsBackground)
        .navigationTitle(Strings.PostDetails.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPostDetails()
        }
    }
    
    private func loadPostDetails() async {
        guard let postId = post.postId, let postIdInt = Int(postId) else { return }
        
        do {
            let details = try await context.service.getPostDetails(for: postIdInt)
            self.details = details
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }
}

private struct PostHeaderCard: View {
    let post: TopListData.Post
    let details: StatsPostDetails
    let context: StatsContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step3) {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                if let dateGMT = details.post?.dateGMT {
                    HStack(spacing: 6) {
                        Text(Strings.PostDetails.published(formatPublishedDate(dateGMT)))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Permalink button
                        if let permalink = details.post?.permalink, let url = URL(string: permalink) {
                            Button(action: {
                                UIApplication.shared.open(url)
                            }) {
                                Image(systemName: "link")
                                    .font(.footnote)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }

            // Metrics with visual separation
            HStack(spacing: Constants.step3) {
                MetricView(metric: .views, value: details.totalViewsCount)

                if let likesCount = post.metrics.likes {
                    MetricView(metric: .likes, value: likesCount)
                }

                if let commentCount = details.post?.commentCount, let count = Int(commentCount) {
                    MetricView(metric: .comments, value: count)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: Constants.step2, leading: Constants.step2, bottom: Constants.step1, trailing: Constants.step2))
    }
    
    private func formatPublishedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = context.timeZone
        return formatter.string(from: date)
    }
}

private struct MetricView: View {
    let metric: SiteMetric
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: metric.systemImage)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)

                Text(metric.localizedTitle.uppercased())
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }

            Text(StatsValueFormatter(metric: metric).format(value: value))
                .contentTransition(.numericText())
                .animation(.spring, value: value)
                .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                .foregroundColor(.primary)
        }
        .lineLimit(1)
        .frame(minWidth: 78, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        PostStatsDetailsView(
            post: .init(
                title: "Apple's Vision Pro is a lonely computer",
                postId: "12345",
                date: .now,
                pageId: nil,
                type: "post",
                author: nil,
                metrics: .init(views: 45892, likes: 26, comments: 487)
            )
        )
        .environment(\.context, StatsContext.demo)
    }
}
