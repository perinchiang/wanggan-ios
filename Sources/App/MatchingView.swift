import SwiftUI

private struct EndpointPreference: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct MatchingView: View {
    let exercise: MatchingExercise
    @Binding var session: LessonSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedLeft: String?

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("给定条件").frame(maxWidth: .infinity)
                Spacer().frame(width: 54)
                Text("对应关系").frame(maxWidth: .infinity)
            }.font(.caption).foregroundStyle(Theme.muted)
            HStack(alignment: .top, spacing: 54) {
                VStack(spacing: 24) {
                    ForEach(exercise.left) { item in endpoint(item, left: true) }
                }.frame(maxWidth: .infinity)
                VStack(spacing: 24) {
                    ForEach(exercise.right) { item in endpoint(item, left: false) }
                }.frame(maxWidth: .infinity)
            }
            .overlayPreferenceValue(EndpointPreference.self) { anchors in
                GeometryReader { geometry in
                    ForEach(exercise.left) { item in
                        if let rightID = session.matches[item.id],
                           let leftAnchor = anchors["left-\(item.id)"],
                           let rightAnchor = anchors["right-\(rightID)"] {
                            let startRect = geometry[leftAnchor]
                            let endRect = geometry[rightAnchor]
                            let start = CGPoint(x: startRect.maxX, y: startRect.midY)
                            let end = CGPoint(x: endRect.minX, y: endRect.midY)
                            Path { path in
                                path.move(to: start)
                                path.addCurve(to: end,
                                              control1: CGPoint(x: start.x + 35, y: start.y),
                                              control2: CGPoint(x: end.x - 35, y: end.y))
                            }
                            .stroke(session.matchingSolved ? Theme.lime : Theme.ink,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        }
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
            }
            HStack {
                Text(selectedLeft == nil ? "先点左边，再点右边" : "再点右边，为它选择对应项")
                    .font(.caption).foregroundStyle(Theme.muted)
                Spacer()
                if !session.matchingSolved {
                    Button("清空") { session.matches = [:]; session.matchingSubmitted = false; selectedLeft = nil }
                        .font(.subheadline).frame(minHeight: 44)
                        .accessibilityIdentifier("clear-matches")
                }
            }
        }
    }

    private func endpoint(_ item: MatchItem, left: Bool) -> some View {
        let chosen = left ? selectedLeft == item.id : false
        let connection = left ? session.matches[item.id] : session.matches.first(where: { $0.value == item.id })?.key
        let connectedName: String? = left
            ? exercise.right.first(where: { $0.id == connection })?.text
            : exercise.left.first(where: { $0.id == connection })?.text
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                if left { selectedLeft = item.id }
                else if let selectedLeft {
                    session.connect(selectedLeft, to: item.id)
                    self.selectedLeft = nil
                }
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: item.symbol).font(.system(size: 28))
                Text(item.text).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity).frame(minHeight: 100).padding(.horizontal, 9).padding(.vertical, 12)
            .background(chosen ? Theme.lime.opacity(0.35) : Theme.surface, in: .rect(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(chosen ? Theme.ink : Theme.line, lineWidth: chosen ? 2 : 1))
            .overlay(alignment: left ? .trailing : .leading) {
                Circle().fill(connection != nil ? Theme.lime : Theme.paper)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 2))
                    .offset(x: left ? 6 : -6)
            }
        }
        .buttonStyle(PressStyle())
        .disabled(session.matchingSolved)
        .anchorPreference(key: EndpointPreference.self, value: .bounds) { ["\(left ? "left" : "right")-\(item.id)": $0] }
        .accessibilityLabel(item.text)
        .accessibilityValue(connectedName.map { "已连接到\($0)" } ?? (chosen ? "已选中，接着选择右侧" : "未连接"))
        .accessibilityIdentifier("match-\(left ? "left" : "right")-\(item.id)")
    }
}
