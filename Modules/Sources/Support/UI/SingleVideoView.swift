import SwiftUI
import AVKit
import AsyncImageKit

struct SingleVideoView: View {

    @State
    private var player: AVPlayer? = nil

    @State
    private var error: Error? = nil

    private let url: URL
    private let host: MediaHostProtocol?

    init(url: URL, host: MediaHostProtocol? = nil) {
        self.url = url
        self.host = host
    }

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else if let error {
                FullScreenErrorView(
                    title: Localization.unableToDisplayVideo,
                    message: error.localizedDescription,
                    systemImage: "film"
                )
            } else {
                FullScreenProgressView(Localization.loadingVideo)
            }
        }.task {
            if let host {
                do {
                    let asset = try await host.authenticatedAsset(for: url)
                    self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                } catch {
                    self.error = error
                }
            } else {
                self.player = AVPlayer(url: url)
            }
        }
    }
}
