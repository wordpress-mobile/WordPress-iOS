import SwiftUI
import UIKit

// MARK: - Context Menu

extension TopListItemView {
    @ViewBuilder
    var contextMenuContent: some View {
        Group {
            // Item-specific actions
            switch item {
            case let post as TopListData.Post:
                postActions(post)
            case let author as TopListData.Author:
                authorActions(author)
            case let referrer as TopListData.Referrer:
                referrerActions(referrer)
            case let location as TopListData.Location:
                locationActions(location)
            case let link as TopListData.ExternalLink:
                externalLinkActions(link)
            case let download as TopListData.FileDownload:
                fileDownloadActions(download)
            case let searchTerm as TopListData.SearchTerm:
                searchTermActions(searchTerm)
            case let video as TopListData.Video:
                videoActions(video)
            case let archiveItem as TopListData.ArchiveItem:
                archiveItemActions(archiveItem)
            case let archiveSection as TopListData.ArchiveSection:
                archiveSectionActions(archiveSection)
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Post Actions
    
    @ViewBuilder
    func postActions(_ post: TopListData.Post) -> some View {
        if let url = post.postURL {
            Button {
                router.openURL(url)
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }
            
            Button {
                UIPasteboard.general.url = url
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
        }
        
        Button {
            UIPasteboard.general.string = post.title
        } label: {
            Label("Copy Title", systemImage: "doc.on.doc")
        }
    }
    
    // MARK: - Author Actions
    
    @ViewBuilder
    func authorActions(_ author: TopListData.Author) -> some View {
        Button {
            UIPasteboard.general.string = author.name
        } label: {
            Label("Copy Name", systemImage: "doc.on.doc")
        }
    }
    
    // MARK: - Referrer Actions
    
    @ViewBuilder
    func referrerActions(_ referrer: TopListData.Referrer) -> some View {
        if let domain = referrer.domain {
            Button {
                if let url = URL(string: "https://\(domain)") {
                    router.openURL(url)
                }
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }
            
            Button {
                UIPasteboard.general.string = domain
            } label: {
                Label("Copy Domain", systemImage: "doc.on.doc")
            }
        }
    }
    
    // MARK: - Location Actions
    
    @ViewBuilder
    func locationActions(_ location: TopListData.Location) -> some View {
        Button {
            UIPasteboard.general.string = location.country
        } label: {
            Label("Copy Country Name", systemImage: "doc.on.doc")
        }
    }
    
    // MARK: - External Link Actions
    
    @ViewBuilder
    func externalLinkActions(_ link: TopListData.ExternalLink) -> some View {
        if let url = URL(string: link.url) {
            Button {
                router.openURL(url)
            } label: {
                Label("Open in Browser", systemImage: "safari")
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
    func fileDownloadActions(_ download: TopListData.FileDownload) -> some View {
        Button {
            UIPasteboard.general.string = download.fileName
        } label: {
            Label("Copy File Name", systemImage: "doc.on.doc")
        }
        
        if let path = download.filePath {
            Button {
                UIPasteboard.general.string = path
            } label: {
                Label("Copy File Path", systemImage: "doc.on.doc")
            }
        }
    }
    
    // MARK: - Search Term Actions
    
    @ViewBuilder
    func searchTermActions(_ searchTerm: TopListData.SearchTerm) -> some View {
        Button {
            let query = searchTerm.term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "https://www.google.com/search?q=\(query)") {
                router.openURL(url)
            }
        } label: {
            Label("Search in Google", systemImage: "magnifyingglass")
        }
        
        Button {
            UIPasteboard.general.string = searchTerm.term
        } label: {
            Label("Copy Search Term", systemImage: "doc.on.doc")
        }
    }
    
    // MARK: - Video Actions
    
    @ViewBuilder
    func videoActions(_ video: TopListData.Video) -> some View {
        if let url = video.videoURL {
            Button {
                router.openURL(url)
            } label: {
                Label("Watch Video", systemImage: "play.circle")
            }
            
            Button {
                UIPasteboard.general.url = url
            } label: {
                Label("Copy Video URL", systemImage: "doc.on.doc")
            }
        }
        
        Button {
            UIPasteboard.general.string = video.title
        } label: {
            Label("Copy Title", systemImage: "doc.on.doc")
        }
    }
    
    // MARK: - Archive Item Actions
    
    @ViewBuilder
    func archiveItemActions(_ archiveItem: TopListData.ArchiveItem) -> some View {
        if let url = URL(string: archiveItem.href) {
            Button {
                router.openURL(url)
            } label: {
                Label("Open in Browser", systemImage: "safari")
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
    func archiveSectionActions(_ section: TopListData.ArchiveSection) -> some View {
        // No specific actions for archive sections
        EmptyView()
    }
}
