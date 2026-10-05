import SwiftUI

struct IPv4FoundationPanel: View {
    let configuration: IPv4Foundation
    @Binding var progress: IPv4FoundationProgress
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
                "点号把它分成四段",
                "四段一共是 32 位",
                "点号是分组边界"
            ][stage]
        case .octetBinary:
            return [
                "一段里面只有 8 位",
                "每一位都有自己的位值",
                "8 位的范围是 0～255",
                "256 已经装不进 8 位"
            ][stage]
        }
    }

    private var explanation: String {
        switch configuration.kind {
        case .addressRole:
            return [
                "这里的 IPv4 地址不是游戏房间号。它标在一台具体电脑旁边，先把“地址属于谁”看清楚。",
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
                "一个八位组有 8 个二进制位，每一位只能是 0 或 1。先看一个具体数怎样放进这 8 个位置。",
                "从左到右，8 个位置的位值依次是 128、64、32、16、8、4、2、1。某一位是 1，就把对应位值加起来。",
                "8 位全是 0 时得到 0；8 位全是 1 时得到 255。这就是一个八位组能表示的完整范围。",
                "255 再加 1 会变成 1 00000000，需要第 9 位。因此 256 不能放进一个 IPv4 八位组。"
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
                .animation(.easeInOut(duration: 0.22), value: stage)

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
        let value = configuration.focusOctet ?? 10
        let bits = binaryString(value)
        return Surface {
            VStack(alignment: .leading, spacing: 16) {
                if stage <= 1 {
                    bitCells(bits: bits, highlights: stage == 1)
                    if stage == 1 {
                        Text(bitEquation(for: value))
                            .font(.subheadline.monospaced().weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                } else if stage == 2 {
                    VStack(spacing: 12) {
                        binaryRangeRow(binary: "00000000", decimal: "0", label: "最小")
                        binaryRangeRow(binary: "11111111", decimal: "255", label: "最大")
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("255 + 1")
                            .font(.headline.monospaced())
                        HStack(spacing: 8) {
                            Text("1")
                                .font(.title3.monospaced().bold())
                                .padding(8)
                                .background(Theme.lime.opacity(0.45), in: .rect(cornerRadius: 8))
                            bitCells(bits: "00000000", highlights: false)
                        }
                        .frame(maxWidth: .infinity)
                        Text("↑ 第 9 位")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
