import SwiftUI

struct ComicStoryPanel: View {
    let story: ComicStory
    let progress: ComicProgress
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(Array(story.panels.prefix(progress.index + 1))) { panel in
                panelContent(panel)
                    .id("comic-panel-" + panel.id)
            }
        }
    }

    private func panelContent(_ panel: ComicPanel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(panel.title).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("comic-title-" + panel.id)
            if let scene = panel.scene {
                Image(scene).resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel(panel.sceneDescription ?? "")
                    .accessibilityIdentifier("comic-scene-" + panel.id)
            }
            if !panel.assets.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 240 : 130))], spacing: 18) {
                    ForEach(panel.assets) { asset in
                        VStack(spacing: 8) {
                            Image("comic-" + asset.id).resizable().scaledToFit().frame(height: 116)
                                .accessibilityHidden(true)
                            Text(asset.name).font(.headline)
                            Text(asset.caption).font(.subheadline).foregroundStyle(Theme.muted)
                                .multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity).padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityElement(children: .combine)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(panel.speaker).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.lime.opacity(0.5), in: Capsule())
                Text(panel.dialogue).font(.title3).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink, lineWidth: 1.3))
                .accessibilityElement(children: .combine)
        }.padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink.opacity(0.7), lineWidth: 1))
    }
}
