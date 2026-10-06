import SwiftUI

private struct EndpointPreference: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct MatchingView: View {
    private struct Selection: Equatable {
        let id: String
        let isLeft: Bool
    }

    let exercise: MatchingExercise
    @Binding var matches: [String: String]
    @Binding var matchingSubmitted: Bool
    @Binding var matchingSolved: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: Selection?

    private var selectionPrompt: String {
        if matchingSolved { return "配对已完成" }
        guard let selection else { return "左右任一侧都可以先选" }
        return selection.isLeft ? "再点右边，为它选择对应项" : "再点左边，为它选择对应项"
    }

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
                        if let rightID = matches[item.id],
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
                            .stroke(matchingSolved ? Theme.lime : Theme.ink,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        }
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
            }
            HStack {
                Text(selectionPrompt)
                    .font(.caption).foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("matching-selection-prompt")
                Spacer()
                if !matchingSolved {
                    Button("清空") { matches = [:]; matchingSubmitted = false; selection = nil }
                        .font(.subheadline).frame(minHeight: 44)
                        .accessibilityIdentifier("clear-matches")
                }
            }
        }
    }

    private func endpoint(_ item: MatchItem, left: Bool) -> some View {
        let chosen = selection == Selection(id: item.id, isLeft: left)
        let connection = left ? matches[item.id] : matches.first(where: { $0.value == item.id })?.key
        let connectedName: String? = left
            ? exercise.right.first(where: { $0.id == connection })?.text
            : exercise.left.first(where: { $0.id == connection })?.text
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                if let previous = selection, previous.isLeft != left {
                    let leftID = left ? item.id : previous.id
                    let rightID = left ? previous.id : item.id
                    matches = matches.filter { $0.key != leftID && $0.value != rightID }
                    matches[leftID] = rightID
                    matchingSubmitted = false
                    selection = nil
                } else {
                    selection = chosen ? nil : Selection(id: item.id, isLeft: left)
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
        .disabled(matchingSolved)
        .anchorPreference(key: EndpointPreference.self, value: .bounds) { ["\(left ? "left" : "right")-\(item.id)": $0] }
        .accessibilityLabel(item.text)
        .accessibilityValue(
            (chosen ? "已选中，接着选择\(left ? "右侧" : "左侧")。" : "") +
            (connectedName.map { "已连接到\($0)" } ?? "未连接")
        )
        .accessibilityIdentifier("match-\(left ? "left" : "right")-\(item.id)")
    }
}
