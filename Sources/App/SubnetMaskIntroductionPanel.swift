import SwiftUI

struct SubnetMaskIntroductionPanel: View {
    let configuration: SubnetMaskIntroduction
    @Binding var progress: SubnetMaskProgress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var headingFocused: Bool

    private var prefix: Int { configuration.prefix(for: progress) }
    private var revealsPartition: Bool {
        progress.stage == 1 || progress.stage == 2 || progress.boundarySolved && progress.stage == 3
    }
    private var title: String {
        switch progress.stage {
        case 0: return "地址有了，分界在哪里？"
        case 1: return "掩码的 1 和 0，分别标记什么？"
        case 2: return "地址不动，只换分界规则"
        default: return "这次，由你选出分界"
        }
    }
    private var explanation: String {
        switch progress.stage {
        case 0:
            return "网络部分用来标识这个配置中的子网，主机部分区分其中的接口。四段数字本身不告诉你如何划分，还需要一条规则：子网掩码。"
        case 1:
            return "掩码同样是 32 位，逐位对应地址。1 标记网络位，0 标记主机位。分别点开网络部分和主机部分的一段，看看里面的 8 位。"
        case 2:
            return "只改变前缀，四段地址仍留在原位。观察哪一段改变了角色：/后面的数表示从左开始有多少位属于网络部分。"
        default:
            return "现在给这条地址配 /\(configuration.practicePrefix)。一个字节有 8 位，从左数网络位，应该在第几段之后分界？选好再检查。"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("观察 \(progress.stage + 1) / 4")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("mask-stage")
                Text(title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
                Text(explanation).font(.body).lineSpacing(4)
                Text("在说明上左滑，或点上一步回看")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture(minimumDistance: 45).onEnded { value in
                if value.translation.width < -60 && abs(value.translation.width) > abs(value.translation.height) * 2 {
                    progress.previous()
                }
            })
            .accessibilityAction(named: "上一步") { progress.previous() }

            if let address = IPv4AddressValue(ip: configuration.ip, prefix: prefix),
               let mask = PrefixMask(prefix: prefix) {
                Text(configuration.ip).font(.title3.monospaced().bold())
                    .accessibilityIdentifier("mask-address")
                if progress.stage > 0 {
                    Text("前缀 /\(prefix)").font(.headline.monospacedDigit())
                        .accessibilityIdentifier("mask-prefix")
                }
                if revealsPartition {
                    Text("掩码 \(mask.decimal)").font(.body.monospaced())
                        .accessibilityIdentifier("mask-decimal")
                    Text("网络 \(mask.networkBitCount) 位 · 主机 \(mask.hostBitCount) 位")
                        .font(.subheadline).accessibilityIdentifier("mask-partition")
                }
                VStack(spacing: 10) {
                    ForEach(1...4, id: \.self) { octet in
                        let selected = progress.stage == 1 ? progress.focusedOctet == octet : progress.selectedBoundary == octet
                        let row = MaskOctetRow(
                            octet: octet, addressValue: Int(address.octets[octet - 1]), mask: mask,
                            revealsPartition: revealsPartition,
                            expanded: progress.stage == 1 && selected, selected: selected,
                            isPractice: progress.stage == 3 && !progress.boundarySolved
                        )
                        if progress.stage == 1 || progress.stage == 3 && !progress.boundarySolved {
                            Button {
                                if progress.stage == 1 { progress.inspect(octet, configuration: configuration) }
                                else { progress.selectBoundary(octet) }
                            } label: { row }
                                .buttonStyle(.plain)
                                .accessibilityLabel(progress.stage == 1
                                    ? "第 \(octet) 段，地址 \(address.octets[octet - 1])，掩码 \(mask.octets[octet - 1])，\(octet * 8 <= prefix ? "网络部分" : "主机部分")，点选查看八位"
                                    : "在第 \(octet) 段后分界")
                                .accessibilityAddTraits(selected ? .isSelected : [])
                                .accessibilityValue(progress.stage == 1 && selected ? "\(mask.binaryOctet(octet))，八位\(octet * 8 <= prefix ? "全 1，标记网络位" : "全 0，标记主机位")" : "")
                                .accessibilityIdentifier("mask-octet-\(octet)")
                        } else {
                            row.accessibilityElement(children: .combine)
                        }
                    }
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: prefix)
                if progress.stage == 1 {
                    Text("已观察：网络部分\(progress.inspectedNetwork ? " ✓" : " 待点选") · 主机部分\(progress.inspectedHost ? " ✓" : " 待点选")")
                        .font(.subheadline).foregroundStyle(Theme.muted)
                    Text("连续的 \(configuration.initialPrefix) 个 1，就是 /\(configuration.initialPrefix)。全 1 的八位写成 255，全 0 写成 0；掩码是分界规则，不是另一台设备的地址。")
                        .font(.body)
                }
                if progress.stage == 2 {
                    Button("切换成 /\(progress.usesAlternate ? configuration.initialPrefix : configuration.alternatePrefix)") {
                        progress.toggleCondition()
                    }
                    .buttonStyle(.bordered).frame(minHeight: 44)
                    .accessibilityIdentifier("mask-condition-toggle")
                    if progress.switchedCondition {
                        Text("地址没有变，网络位数从 \(configuration.initialPrefix) 变成 \(configuration.alternatePrefix)，主机位数从 \(32 - configuration.initialPrefix) 变成 \(32 - configuration.alternatePrefix)。分界由掩码决定。")
                            .font(.body)
                    }
                }
                if progress.stage == 3 && progress.boundarySubmitted {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(progress.boundarySolved ? "分界找对了" : "再数一数网络位",
                              systemImage: progress.boundarySolved ? "checkmark.circle" : "lightbulb")
                            .font(.headline)
                        Text(progress.boundarySolved
                            ? "前 \(prefix) 位是网络部分，其余 \(32 - prefix) 位是主机部分。掩码与 /\(prefix) 表达同一条分界规则。"
                            : "每段 8 位，/\(prefix) 要从左数 \(prefix) 位。可以改选，再检查一次。")
                            .font(.body)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.lime.opacity(0.25), in: .rect(cornerRadius: 18))
                    .accessibilityIdentifier("mask-boundary-feedback").id("mask-feedback")
                }
            }
            Button { progress.previous() } label: { Label("上一步", systemImage: "arrow.left") }
                .frame(minHeight: 44).disabled(progress.stage == 0)
                .accessibilityIdentifier("mask-previous")
        }
        .onChange(of: progress.stage) { _, _ in headingFocused = true }
    }
}

// Pilot building block: focus/annotation and local decomposition share a stable byte row.
// Its inputs are address/mask values, never a lesson ID or business ledger.
private struct MaskOctetRow: View {
    let octet: Int
    let addressValue: Int
    let mask: PrefixMask
    let revealsPartition: Bool
    let expanded: Bool
    let selected: Bool
    let isPractice: Bool
    @ScaledMetric(relativeTo: .body) private var bitWidth: CGFloat = 28

    private var network: Bool { octet * 8 <= mask.prefix }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("第 \(octet) 段 · \(addressValue)").font(.headline.monospacedDigit())
            if revealsPartition {
                Text("掩码 \(mask.octets[octet - 1]) · \(network ? "网络部分" : "主机部分")")
                    .font(.subheadline)
            } else if isPractice {
                Label("在这一段后分界", systemImage: selected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
            } else {
                Text("8 位").font(.subheadline).foregroundStyle(Theme.muted)
            }
            if expanded {
                // Adaptive cells preserve each bit at large text sizes, rather than shrinking 8 digits.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: bitWidth), spacing: 6)], spacing: 6) {
                    ForEach(1...8, id: \.self) { _ in
                        Text(network ? "1" : "0").font(.body.monospaced().bold())
                            .frame(minWidth: bitWidth, minHeight: bitWidth + 4)
                            .background(Theme.surface, in: .rect(cornerRadius: 6))
                    }
                }.accessibilityHidden(true)
                Text("这 8 位\(network ? "全是 1，写成 255，标记网络位" : "全是 0，写成 0，标记主机位")")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .foregroundStyle(Theme.ink)
        .background(revealsPartition && network ? Theme.lime.opacity(0.35) : Theme.surface, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(selected ? Theme.ink : Theme.line, lineWidth: selected ? 2 : 1))
    }
}
