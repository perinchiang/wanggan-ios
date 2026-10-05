import SwiftUI

struct IPv4IntroductionPanel: View {
    let introduction: IPv4Introduction
    @Binding var progress: IPv4IntroductionProgress
    let fontScale: Double
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AccessibilityFocusState private var headingFocused: Bool
    @State private var height: CGFloat = 250
    @State private var failed = false
    @State private var reloadID = UUID()

    private var title: String {
        switch progress.stage {
        case 0: return "先选一段地址"
        case 1: return "一段里面，恰好 8 位"
        case 2: return "8 位能表示多大的数？"
        default: return "四段，合起来是 32 位"
        }
    }

    private var explanation: String {
        switch progress.stage {
        case 0: return "点号把地址分成四段。点选下面任意一段，再把它拆开。"
        case 1: return "每个小格是一位，只能是 0 或 1。8 位组成一个字节；十进制的一段数字，就是这个字节方便人阅读的写法。"
        case 2: return "从全 0 切换到全 1，看看同样的 8 个位置能表示的最小值和最大值。"
        default: return "每段都是 8 位，四段共 32 位。即使写成一位数，也不会少占几个二进制位；点号帮助阅读，不占地址位数。"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("观察 \(progress.stage + 1) / 4").font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.muted).accessibilityIdentifier("intro-stage")
                Text(title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
                Text(explanation).font(.body).lineSpacing(4)
                Text("在这段说明上左滑，可回看上一步").font(.caption).foregroundStyle(Theme.muted)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture(minimumDistance: 45).onEnded { value in
                if value.translation.width < -60 && abs(value.translation.width) > abs(value.translation.height) * 2 {
                    progress.previous()
                }
            })
            .accessibilityAction(named: "上一步") { progress.previous() }

            if failed {
                fallback
                Button("重试图示") { failed = false; reloadID = UUID() }.frame(minHeight: 44)
            } else {
                IPv4AddressVisualWebView(
                    example: IPv4VisualExample(ip: introduction.ip, prefix: 32, mode: .explain),
                    selectedOctet: progress.selectedOctet, solved: false, theme: colorScheme,
                    fontScale: fontScale, reduceMotion: reduceMotion, isActive: scenePhase == .active,
                    onSelect: { progress.selectOctet($0) },
                    onHeight: { if abs(height - $0) > 2 { height = $0 } },
                    onFailure: { failed = true }, introduction: progress
                ).id(reloadID).frame(height: height)
            }
            if progress.stage == 2 {
                Button(progress.rangeValue == 0 ? "把 8 位全部变成 1" : "再看看全 0") {
                    progress.toggleRange()
                }
                .buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("intro-range-toggle")
                if progress.inspectedRange {
                    Text("00000000 = 0，11111111 = 255。包含 0，一共 256 种取值；256 本身已经需要第 9 位。")
                        .font(.body).accessibilityIdentifier("intro-range-explanation")
                }
            }
            Button { progress.previous() } label: { Label("上一步", systemImage: "arrow.left") }
                .frame(minHeight: 44).disabled(progress.stage == 0)
                .accessibilityIdentifier("intro-previous")
        }
        .onChange(of: progress.stage) { _, _ in headingFocused = true }
    }

    @ViewBuilder private var fallback: some View {
        if let address = IPv4AddressValue(ip: introduction.ip, prefix: 32) {
            Surface {
                VStack(alignment: .leading, spacing: 12) {
                    Text(introduction.ip).font(.headline.monospaced())
                    if progress.stage == 0 {
                        ForEach(1...4, id: \.self) { octet in
                            Button("第 \(octet) 段：\(address.octets[octet - 1])") { progress.selectOctet(octet) }
                                .frame(minHeight: 44)
                                .accessibilityAddTraits(progress.selectedOctet == octet ? .isSelected : [])
                        }
                    } else if progress.stage == 1, let octet = progress.selectedOctet {
                        Text("第 \(octet) 段：\(address.octets[octet - 1]) = \(address.binaryOctets[octet - 1])（8 位）")
                            .font(.body.monospaced())
                    } else if progress.stage == 2 {
                        Text(progress.rangeValue == 0 ? "00000000 = 0" : "11111111 = 255").font(.body.monospaced())
                    } else {
                        ForEach(1...4, id: \.self) { octet in
                            Text("\(address.octets[octet - 1]) = \(address.binaryOctets[octet - 1])").font(.body.monospaced())
                        }
                        Text("4 × 8 = 32 位").font(.headline)
                    }
                }
            }
        }
    }
}
