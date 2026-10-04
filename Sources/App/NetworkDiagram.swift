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
            ZStack {
                Path { path in
                    path.move(to: computer); path.addLine(to: nas)
                    path.move(to: hub); path.addLine(to: router)
                }.stroke(Theme.line, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                if animated {
                    Path { path in path.move(to: computer); path.addLine(to: nas) }
                        .trim(from: 0, to: traveling ? 1 : 0)
                        .stroke(Theme.lime, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    Circle().fill(Theme.ink).frame(width: 9, height: 9)
                        .position(x: traveling ? nas.x : computer.x, y: hub.y)
                }
                device("laptopcomputer", "电脑", at: computer)
                device("switch.2", "交换机", at: hub)
                device(kind == "dns" ? "server.rack" : "externaldrive", kind == "dns" ? "服务器" : "NAS", at: nas)
                device("wifi.router", "路由器", at: router)
            }
        }
        .frame(height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("示意图：电脑和 NAS 连接同一交换机，路由器是交换机旁的一条分支。本地通信可以通过交换机直接到达 NAS。")
        .task(id: animated) {
            guard animated else { return }
            if reduceMotion { traveling = true }
            else {
                withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: false)) { traveling = true }
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

struct ConceptIllustration: View {
    let lesson: Lesson
    var animated = false
    var body: some View {
        if lesson.diagram == "gateway" || lesson.diagram == "arp" {
            NetworkDiagram(animated: animated)
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
