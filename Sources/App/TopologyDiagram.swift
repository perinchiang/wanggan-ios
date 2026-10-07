import SwiftUI

/// Data-driven native topology diagram. Renders nodes as system symbols with
/// labels, links as lines, and an optional traveling packet along the flow path.
/// Stages reveal nodes and links progressively, one per explanation paragraph.
struct TopologyDiagram: View {
    let spec: TopologySpec
    /// 1-based reveal stage; `Int.max` shows everything.
    var stage = Int.max
    var animated = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var traveling = false

    private var visibleNodes: [TopologyNode] { spec.nodes(visibleAt: stage) }
    private var visibleLinks: [TopologyLink] { spec.links(visibleAt: stage) }
    private var flowReady: Bool { stage >= spec.flowStage }

    var body: some View {
        GeometryReader { geometry in
            let columns = max(spec.nodes.map(\.column).max() ?? 0, 0) + 1
            let rows = max(spec.nodes.map(\.row).max() ?? 0, 0) + 1
            let position = { (column: Int, row: Int) in
                CGPoint(x: geometry.size.width * (CGFloat(column) + 0.5) / CGFloat(columns),
                        y: geometry.size.height * (CGFloat(row) + 0.5) / CGFloat(rows))
            }
            let centers = Dictionary(uniqueKeysWithValues: spec.nodes.map {
                ($0.id, position($0.column, $0.row))
            })
            ZStack {
                ForEach(visibleLinks) { link in
                    linkView(link, centers: centers)
                }
                if flowReady {
                    let points = spec.flow.compactMap { centers[$0] }
                    FlowPath(points: points)
                        .trim(from: 0, to: traveling ? 1 : 0)
                        .stroke(Theme.lime, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    TravelingPacket(progress: traveling ? 1 : 0, points: points)
                        .fill(Theme.ink)
                }
                ForEach(visibleNodes) { node in
                    nodeView(node, at: centers[node.id] ?? .zero)
                }
            }
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stage >= spec.maxStage ? spec.accessibilitySummary : "示意图")
        .accessibilityValue("当前显示：" + visibleNodes.map(\.label).joined(separator: "、"))
        .accessibilityIdentifier("topology-diagram")
        .task(id: flowReady) {
            guard flowReady, animated else { return }
            if reduceMotion { traveling = true }
            else {
                withAnimation(.easeInOut(duration: 1.7).repeatCount(2, autoreverses: false)) { traveling = true }
            }
        }
    }

    private func linkView(_ link: TopologyLink, centers: [String: CGPoint]) -> some View {
        let from = centers[link.from] ?? .zero
        let to = centers[link.to] ?? .zero
        let wireless = link.wireless == true
        return ZStack {
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(Theme.line, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: wireless ? [5, 5] : []))
            if wireless {
                Image(systemName: "wifi").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .position(midpoint(from, to))
            }
        }
        .transition(.opacity)
    }

    private func nodeView(_ node: TopologyNode, at point: CGPoint) -> some View {
        let focused = stage != Int.max && node.stage == stage
        return VStack(spacing: 6) {
            Image(systemName: node.symbol).font(.system(size: 27, weight: focused ? .semibold : .regular))
                .frame(width: 52, height: 40)
                .background(focused ? Theme.lime.opacity(0.55) : Theme.paper, in: .rect(cornerRadius: 8))
            Text(node.label).font(.caption.weight(focused ? .bold : .medium))
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 7).padding(.vertical, 5)
        .background(focused ? Theme.lime.opacity(0.18) : Color.clear, in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(focused ? Theme.ink.opacity(0.7) : Color.clear, lineWidth: 1.5)
        }
        .opacity(stage != Int.max && !focused ? 0.62 : 1)
        .position(point)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: stage)
        .transition(.opacity.combined(with: .scale(scale: 0.7)))
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

/// The polyline the packet travels along, trimmed by animated progress.
private struct FlowPath: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        return path
    }
}

/// A packet dot that follows the flow polyline, generalizing the single-hop
/// `TravelingPacket` in NetworkDiagram to any number of segments.
private struct TravelingPacket: Shape {
    var progress: Double
    let points: [CGPoint]
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        guard points.count >= 2, progress > 0 else { return Path() }
        let segments = points.count - 1
        let traveled = min(max(progress, 0), 1) * Double(segments)
        let index = min(Int(traveled), segments - 1)
        let fraction = CGFloat(traveled - Double(index))
        let from = points[index]
        let to = points[index + 1]
        let point = CGPoint(x: from.x + (to.x - from.x) * fraction, y: from.y + (to.y - from.y) * fraction)
        return Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10))
    }
}
