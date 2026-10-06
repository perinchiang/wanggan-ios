import SwiftUI

struct IPv4FoundationPanel: View {
    let configuration: IPv4Foundation
    var usesStaticPresentation = false
    @Binding var progress: IPv4FoundationProgress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var headingFocused: Bool

    private var stage: Int {
        min(max(progress.stage, 0), configuration.stageCount - 1)
    }

    private var title: String {
        switch configuration.kind {
        case .addressRole:
            return [
                "先认出这串地址",
                "请求要有明确目标",
                "通信双方都有自己的地址",
                "它不是永久身份证"
            ][stage]
        case .addressFormat:
            return [
                "先看看 IPv4 长什么样",
                "把长串数字切成四小块",
                "每一小块有八个位置",
                "拼回去，还是同一个地址"
            ][stage]
        case .octetBinary:
            return [
                "八个开关，先全部关上",
                "亮起一个，得到 8",
                "再亮一个，得到 12",
                "再加上 1，就得到 13",
                "关掉 4，13 变成 9",
                "全部亮起，最多是 255"
            ][stage]
        }
    }

    private var explanation: String {
        switch configuration.kind {
        case .addressRole:
            return [
                "你想和朋友联机。朋友发来电脑当前的 IP 地址，下图把地址标在他的电脑旁边。先看看：这条消息要发给谁？",
                "发送数据时，请求会带着目标 IP。网络据此知道这份数据最终要交给哪个网络层目标。",
                "回应也需要明确目标。你的电脑同样有自己当前使用的 IP 地址。",
                "IP 更像当前网络里的地址。设备换到别的网络后，地址可能改变，所以它不是设备永久不变的身份证。"
            ][stage]
        case .addressFormat:
            return [
                "常见 IPv4 文本形式都有相同外形：四段十进制数字，中间用三个点分开。",
                "以 192.168.1.23 为例，四段分别是 192、168、1、23。点号把四个八位组的边界写出来。",
                "IPv4 地址本身一共 32 位；常见写法把它按 8 位一组分成四组，再把每组写成十进制。",
                "所以点号不是装饰，也不能随便挪。它决定四个八位组在哪里分开。每段为什么最大是 255，下一课再从二进制解释。"
            ][stage]
        case .octetBinary:
            return [
                "把每一位想成一个开关：关是 0，开是 1。开关下面的数字，是它亮起来时贡献的数值。我们一起看它们怎样拼出 13。",
                "先亮起标着 8 的开关。其他都关着，所以现在是 8。",
                "再亮起标着 4 的开关。8 + 4，现在是 12。",
                "最后亮起标着 1 的开关。8 + 4 + 1 = 13。电脑用 00001101 记住这个数，不需要你背下来。",
                "现在把 4 关掉，8 和 1 还亮着，数就变成 9。每个位置的开关，都会影响最终的数。",
                "八个开关全亮，是 255；全关，是 0。再大一点的 256 要多出第九个位置，这一小块已经放不下了。"
            ][stage]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 9) {
                Text("观察 \(stage + 1) / \(configuration.stageCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("foundation-stage")
                Text(title)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
                Text(explanation)
                    .font(.body)
                    .lineSpacing(4)
            }

            visual
                .animation(reduceMotion || usesStaticPresentation ? nil : .easeInOut(duration: 0.22), value: stage)

            Button {
                progress.previous()
            } label: {
                Label("上一步", systemImage: "arrow.left")
            }
            .frame(minHeight: 44)
            .disabled(stage == 0)
            .accessibilityIdentifier("foundation-previous")
        }
        .onChange(of: progress.stage) { _, _ in
            headingFocused = true
        }
    }

    @ViewBuilder
    private var visual: some View {
        switch configuration.kind {
        case .addressRole:
            addressRoleVisual
        case .addressFormat:
            addressFormatVisual
        case .octetBinary:
            octetBinaryVisual
        }
    }

    private var addressRoleVisual: some View {
        Surface {
            VStack(spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    deviceCard(symbol: "laptopcomputer", name: "你的电脑", address: stage >= 2 ? (configuration.peerIP ?? "") : nil)
                    Image(systemName: "arrow.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(stage >= 1 ? Theme.ink : Theme.line)
                        .padding(.top, 28)
                        .accessibilityHidden(true)
                    deviceCard(symbol: "desktopcomputer", name: "朋友的电脑", address: configuration.ip)
                }

                if stage >= 1 {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                        Text("请求目标")
                            .foregroundStyle(Theme.muted)
                        Text(configuration.ip)
                            .font(.body.monospaced().weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.lime.opacity(0.45), in: .capsule)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("请求目标 \(configuration.ip)")
                }

                if stage >= 2, let peer = configuration.peerIP {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.left")
                        Text("回应目标")
                            .foregroundStyle(Theme.muted)
                        Text(peer)
                            .font(.body.monospaced().weight(.semibold))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("回应目标 \(peer)")
                }

                if stage >= 3 {
                    Label("换到别的网络后，IP 地址可能变化", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("foundation-address-role")
    }

    private func deviceCard(symbol: String, name: String, address: String?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .regular))
                .frame(width: 54, height: 44)
            Text(name)
                .font(.subheadline.weight(.semibold))
            if let address, !address.isEmpty {
                Text(address)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Theme.line.opacity(0.45), in: .capsule)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var addressFormatVisual: some View {
        Surface {
            VStack(alignment: .leading, spacing: 16) {
                if stage == 0 {
                    ForEach(configuration.samples ?? [configuration.ip], id: \.self) { sample in
                        HStack(spacing: 10) {
                            Image(systemName: "number")
                                .foregroundStyle(Theme.muted)
                            Text(sample)
                                .font(.title3.monospaced().weight(.semibold))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("IPv4 地址 \(sample)")
                    }
                } else if let address = IPv4AddressValue(ip: configuration.ip, prefix: 32) {
                    HStack(spacing: 5) {
                        ForEach(Array(address.octets.enumerated()), id: \.offset) { index, octet in
                            VStack(spacing: 6) {
                                Text(String(Int(octet)))
                                    .font(.headline.monospaced())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Theme.lime.opacity(0.24), in: .rect(cornerRadius: 12))
                                if stage >= 2 {
                                    Text("8 位")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                            if index < 3 {
                                Text(".")
                                    .font(.title2.bold())
                                    .accessibilityLabel("点号")
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("四段地址 \(configuration.ip)")

                    if stage >= 2 {
                        Text("8 + 8 + 8 + 8 = 32 位")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }

                    if stage >= 3 {
                        HStack(spacing: 7) {
                            Image(systemName: "scissors")
                            Text("点号只负责分隔四个八位组，本身不占地址位。")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Theme.muted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("foundation-address-format")
    }

    private var octetBinaryVisual: some View {
        let values = [0, 8, 12, 13, 9, 255]
        let value = values[stage]
        return Surface {
            VStack(alignment: .leading, spacing: 16) {
                bitCells(bits: binaryString(value), highlights: true)
                Text(bitEquation(for: value))
                    .font(.subheadline.monospaced().weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("foundation-bit-equation")
                if stage == 5 {
                    Text("256 = 1 00000000 → 需要第 9 位")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("foundation-octet-binary")
    }

    private func bitCells(bits: String, highlights: Bool) -> some View {
        let characters = Array(bits)
        let weights = [128, 64, 32, 16, 8, 4, 2, 1]
        return VStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(Array(characters.enumerated()), id: \.offset) { index, bit in
                    Text(String(bit))
                        .font(.headline.monospaced())
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(
                            highlights && bit == "1" ? Theme.lime.opacity(0.55) : Theme.line.opacity(0.45),
                            in: .rect(cornerRadius: 8)
                        )
                }
            }
            if highlights {
                HStack(spacing: 4) {
                    ForEach(weights, id: \.self) { weight in
                        Text(String(weight))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("二进制 \(bits)")
    }

    private func binaryRangeRow(binary: String, decimal: String, label: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .frame(width: 34, alignment: .leading)
            Text(binary)
                .font(.headline.monospaced())
            Spacer(minLength: 4)
            Text("= \(decimal)")
                .font(.headline.monospaced())
        }
        .accessibilityElement(children: .combine)
    }

    private func binaryString(_ value: Int) -> String {
        let raw = String(value, radix: 2)
        return String(repeating: "0", count: max(0, 8 - raw.count)) + raw
    }

    private func bitEquation(for value: Int) -> String {
        let weights = [128, 64, 32, 16, 8, 4, 2, 1]
        let selected = weights.filter { value & $0 != 0 }
        let left = selected.isEmpty ? "0" : selected.map { String($0) }.joined(separator: " + ")
        return "\(left) = \(value)"
    }
}
