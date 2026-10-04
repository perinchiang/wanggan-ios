import SwiftUI

struct NetworkDiagram: View {
    var animated = false
    var kind = "gateway"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var traveling = false

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let computer = CGPoint(x: w * 0.13, y: h * 0.7)
            let hub = CGPoint(x: w * 0.5, y: h * 0.7)
            let nas = CGPoint(x: w * 0.87, y: h * 0.7)
            let router = CGPoint(x: w * 0.5, y: h * 0.2)
            let destination = kind == "arp" ? router : nas
            ZStack {
                Path { path in
                    path.move(to: computer); path.addLine(to: nas)
                    path.move(to: hub); path.addLine(to: router)
                }.stroke(Theme.line, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                if animated {
                    Path { path in path.move(to: computer); path.addLine(to: hub); path.addLine(to: destination) }
                        .trim(from: 0, to: traveling ? 1 : 0)
                        .stroke(Theme.lime, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    TravelingPacket(progress: traveling ? 1 : 0, start: computer, middle: hub, end: destination)
                        .fill(Theme.ink)
                }
                device("laptopcomputer", "电脑", at: computer)
                device("switch.2", "交换机", at: hub)
                device(kind == "dns" ? "server.rack" : "externaldrive", kind == "dns" ? "服务器" : "NAS", at: nas)
                device("wifi.router", "路由器", at: router)
            }
        }
        .frame(height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind == "arp" ? "示意图：访问远方时，第一跳从电脑经过交换机交给本地网关。" : "示意图：电脑和 NAS 连接同一交换机，路由器是交换机旁的一条分支。本地通信可以通过交换机直接到达 NAS。")
        .task(id: animated) {
            guard animated else { return }
            if reduceMotion { traveling = true }
            else {
                withAnimation(.easeInOut(duration: 1.7).repeatCount(2, autoreverses: false)) { traveling = true }
            }
        }
    }

    private func device(_ symbol: String, _ label: String, at point: CGPoint) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 29, weight: .regular))
                .frame(width: 52, height: 40).background(Theme.paper, in: .rect(cornerRadius: 8))
            Text(label).font(.caption.weight(.medium))
        }.position(point)
    }
}

private struct TravelingPacket: Shape {
    var progress: Double
    let start: CGPoint
    let middle: CGPoint
    let end: CGPoint
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        let firstHalf = progress < 0.5
        let from = firstHalf ? start : middle
        let to = firstHalf ? middle : end
        let fraction = CGFloat(firstHalf ? progress * 2 : (progress - 0.5) * 2)
        let point = CGPoint(x: from.x + (to.x - from.x) * fraction, y: from.y + (to.y - from.y) * fraction)
        return Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10))
    }
}

struct ConceptIllustration: View {
    let lesson: Lesson
    var animated = false
    var body: some View {
        if lesson.diagram == "gateway" || lesson.diagram == "arp" {
            NetworkDiagram(animated: animated, kind: lesson.diagram)
        } else {
            Surface {
                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        Image(systemName: lesson.diagram == "dns" ? "text.magnifyingglass" : "network")
                            .font(.largeTitle).padding(14).background(Theme.lime, in: .rect(cornerRadius: 18))
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lesson.diagram == "subnet" ? "192.168.1.10 /24" : lesson.diagram == "hop" ? "IP 包 → 下一跳的帧" : "名字 → 地址")
                                .font(.headline.monospaced())
                            Text(lesson.diagram == "subnet" ? "地址 + 掩码，一起判断" : lesson.diagram == "hop" ? "每一段链路，重新交付" : "解析成功，再尝试连接")
                                .font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}
