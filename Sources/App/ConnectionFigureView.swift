import SwiftUI

/// A physical connection picture, independent of lesson ID and question type.
struct ConnectionFigureView: View {
    let figure: ConnectionFigure
    var body: some View {
        VStack(spacing: 10) {
            if let caption = figure.caption {
                Text(caption).font(.subheadline.weight(.semibold))
            }
            HStack(spacing: 0) {
                Image(systemName: figure.device.symbol)
                    .font(.system(size: 40, weight: .medium)).frame(width: 64, height: 64)
                VStack(spacing: 6) {
                    if figure.medium == .wifi {
                        Image(systemName: "wifi").font(.system(size: 27, weight: .semibold))
                    } else {
                        HStack(spacing: 0) {
                            connector
                            Rectangle().fill(Theme.ink).frame(height: 3)
                            connector
                        }.frame(height: 30)
                    }
                    if figure.showMediumLabel {
                        Text(figure.medium == .wifi ? "Wi-Fi" : "网线").font(.caption)
                    }
                }.frame(maxWidth: .infinity).padding(.horizontal, 4)
                ZStack {
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.ink, lineWidth: 2)
                        .frame(width: 54, height: 33)
                    HStack(spacing: 5) {
                        ForEach(0..<3) { _ in Circle().fill(Theme.ink).frame(width: 3, height: 3) }
                    }.offset(y: 7)
                }.frame(width: 64, height: 64)
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(figure.caption.map { $0 + "，" } ?? "")\(figure.device.name)\(figure.medium == .wifi ? "通过 Wi-Fi" : "用网线")连接家庭网络设备")
    }
    private var connector: some View {
        RoundedRectangle(cornerRadius: 1).strokeBorder(Theme.ink, lineWidth: 2)
            .frame(width: 10, height: 14)
    }
}
