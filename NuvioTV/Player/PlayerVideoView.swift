import KSPlayer
import SwiftUI
import UIKit

/// Hosts the current engine's video view. KSPlayerLayer swaps the underlying
/// player (native ↔ FFmpeg) during failover and re-parents the new view into
/// the old one's superview itself, so this container just has to attach the
/// current view and clean up strays whenever `videoRefreshID` changes.
///
/// Deliberately NOT `@ObservedObject`: observing the view model made every
/// published change re-run `updateUIView`. The parent passes `refreshID`
/// (bumped only when the engine/player instance may have changed) so SwiftUI
/// re-invokes us exactly when re-attachment could be needed.
struct PlayerVideoView: UIViewRepresentable {
    let viewModel: PlayerViewModel
    let refreshID: UUID

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        attach(to: container)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        attach(to: container)
    }

    private func attach(to container: UIView) {
        // The active engine's render view (KSPlayer's player view or VLC's
        // drawable) — bumped via videoRefreshID when the engine changes.
        guard let videoView = viewModel.activeVideoView else { return }
        for subview in container.subviews where subview !== videoView {
            subview.removeFromSuperview()
        }
        guard videoView.superview !== container else { return }
        videoView.removeFromSuperview()
        container.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: container.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}

/// Renders the active subtitle cues from KSPlayer's SubtitleModel: text cues
/// bottom-centered in Nuvio's caption style, bitmap cues (PGS/VobSub) fitted
/// over the video.
struct SubtitleOverlayView: View {
    @ObservedObject var model: SubtitleModel
    var settings: PlayerSettings = .default

    var body: some View {
        ZStack {
            ForEach(model.parts) { part in
                if let image = part.image {
                    GeometryReader { geo in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geo.size.width * 0.9)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 60)
                    }
                } else if let text = part.text {
                    // Broadcast-caption look: modest size (the font itself is
                    // stamped by SubtitleModel.textFont — configured to 36pt),
                    // tight dark plate, double shadow for readability on
                    // bright scenes, safe-area bottom margin.
                    VStack {
                        Spacer()
                        Text(AttributedString(text))
                            .font(.system(size: CGFloat(settings.subtitleSize), weight: settings.subtitleBold ? .bold : .medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .shadow(color: .black.opacity(0.95), radius: 2, y: 1)
                            .shadow(color: .black.opacity(0.6), radius: 8)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 9)
                            .background(
                                .black.opacity(settings.subtitleBackground ? 0.42 : 0),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .padding(.bottom, 84)
                            .frame(maxWidth: 1200)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
