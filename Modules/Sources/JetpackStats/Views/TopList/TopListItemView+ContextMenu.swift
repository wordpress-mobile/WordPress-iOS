import SwiftUI
import UIKit

// MARK: - Context Menu

extension TopListItemView {
    @ViewBuilder
    var contextMenuContent: some View {
        Group {
            // Item-specific actions
            switch item {
            case let post as TopListItem.Post:
                postActions(post)
            case let author as TopListItem.Author:
                authorActions(author)
            case let referrer as TopListItem.Referrer:
                referrerActions(referrer)
            case let location as TopListItem.Location:
                locationActions(location)
            case let link as TopListItem.ExternalLink:
                externalLinkActions(link)
            case let download as TopListItem.FileDownload:
                fileDownloadActions(download)
            case let searchTerm as TopListItem.SearchTerm:
                searchTermActions(searchTerm)
            case let video as TopListItem.Video:
                videoActions(video)
            case let archiveItem as TopListItem.ArchiveItem:
                archiveItemActions(archiveItem)
            case let archiveSection as TopListItem.ArchiveSection:
                archiveSectionActions(archiveSection)
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Post Actions

    @ViewBuilder
    func postActions(_ post: TopListItem.Post) -> some View {
        if let url = post.postURL {
            Button {
                router.openURL(url)
            } label: {
                Label(Strings.ContextMenuActions.openInBrowser, systemImage: "safari")
            }

            Button {
                UIPasteboard.general.url = url
            } label: {
                Label(Strings.ContextMenuActions.copyURL, systemImage: "doc.on.doc")
            }
        }

        Button {
            UIPasteboard.general.string = post.title
        } label: {
            Label(Strings.ContextMenuActions.copyTitle, systemImage: "doc.on.doc")
        }
    }

    // MARK: - Author Actions

    @ViewBuilder
    func authorActions(_ author: TopListItem.Author) -> some View {
        Button {
            UIPasteboard.general.string = author.name
        } label: {
            Label(Strings.ContextMenuActions.copyName, systemImage: "doc.on.doc")
        }
    }

    // MARK: - Referrer Actions

    @ViewBuilder
    func referrerActions(_ referrer: TopListItem.Referrer) -> some View {
        if let domain = referrer.domain {
            Button {
                if let url = URL(string: "https://\(domain)") {
                    router.openURL(url)
                }
            } label: {
                Label(Strings.ContextMenuActions.openInBrowser, systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string = domain
            } label: {
                Label(Strings.ContextMenuActions.copyDomain, systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Location Actions

    @ViewBuilder
    func locationActions(_ location: TopListItem.Location) -> some View {
        Button {
            UIPasteboard.general.string = location.name
        } label: {
            Label(Strings.ContextMenuActions.copyCountryName, systemImage: "doc.on.doc")
        }
    }

    // MARK: - External Link Actions

    @ViewBuilder
    func externalLinkActions(_ link: TopListItem.ExternalLink) -> some View {
        if let url = URL(string: link.url) {
            Button {
                router.openURL(url)
            } label: {
                Label(Strings.ContextMenuActions.openInBrowser, systemImage: "safari")
            }
        }

        Button {
            UIPasteboard.general.string = link.url
        } label: {
            Label("Copy URL", systemImage: "doc.on.doc")
        }
    }

    // MARK: - File Download Actions

    @ViewBuilder
    func fileDownloadActions(_ download: TopListItem.FileDownload) -> some View {
        Button {
            UIPasteboard.general.string = download.fileName
        } label: {
            Label(Strings.ContextMenuActions.copyFileName, systemImage: "doc.on.doc")
        }

        if let path = download.filePath {
            Button {
                UIPasteboard.general.string = path
            } label: {
                Label(Strings.ContextMenuActions.copyFilePath, systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Search Term Actions

    @ViewBuilder
    func searchTermActions(_ searchTerm: TopListItem.SearchTerm) -> some View {
        Button {
            let query = searchTerm.term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "https://www.google.com/search?q=\(query)") {
                router.openURL(url)
            }
        } label: {
            Label(Strings.ContextMenuActions.searchInGoogle, systemImage: "magnifyingglass")
        }

        Button {
            UIPasteboard.general.string = searchTerm.term
        } label: {
            Label(Strings.ContextMenuActions.copySearchTerm, systemImage: "doc.on.doc")
        }
    }

    // MARK: - Video Actions

    @ViewBuilder
    func videoActions(_ video: TopListItem.Video) -> some View {
        if let url = video.videoURL {
            Button {
                router.openURL(url)
            } label: {
                Label(Strings.ContextMenuActions.openInBrowser, systemImage: "safari")
            }

            Button {
                UIPasteboard.general.url = url
            } label: {
                Label(Strings.ContextMenuActions.copyVideoURL, systemImage: "doc.on.doc")
            }
        }

        Button {
            UIPasteboard.general.string = video.title
        } label: {
            Label(Strings.ContextMenuActions.copyTitle, systemImage: "doc.on.doc")
        }
    }

    // MARK: - Archive Item Actions

    @ViewBuilder
    func archiveItemActions(_ archiveItem: TopListItem.ArchiveItem) -> some View {
        if let url = URL(string: archiveItem.href) {
            Button {
                router.openURL(url)
            } label: {
                Label(Strings.ContextMenuActions.openInBrowser, systemImage: "safari")
            }
        }

        Button {
            UIPasteboard.general.string = archiveItem.href
        } label: {
            Label("Copy URL", systemImage: "doc.on.doc")
        }
    }

    // MARK: - Archive Section Actions

    @ViewBuilder
    func archiveSectionActions(_ section: TopListItem.ArchiveSection) -> some View {
        // No specific actions for archive sections
        EmptyView()
    }
}
