import SwiftUI

struct MatchingView: View {
    private struct Selection: Equatable {
        let id: String
        let isLeft: Bool
    }
    private struct Pair: Equatable {
        let left: String
        let right: String
    }

    let exercise: MatchingExercise
    let matches: [String: String]
    let onPair: (String, String) -> Bool
    var usesStaticPresentation = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var selection: Selection?
    @State private var pending: Pair?
    @State private var error: Pair?
    @State private var errorPulse = false

    private var reduceMotion: Bool { systemReduceMotion || usesStaticPresentation }
    private var solved: Bool { exercise.isCorrect(matches) }
    private var selectionPrompt: String {
        if solved { return "配对已完成" }
        if error != nil { return "这两项不匹配，换一个试试" }
        if pending != nil { return "看看这两项是否对应" }
        guard let selection else { return "左右任一侧都可以先选" }
        return selection.isLeft ? "再点右边，为它选择对应项" : "再点左边，为它选择对应项"
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 14) {
                    ForEach(exercise.left) { endpoint($0, left: true) }
                }.frame(maxWidth: .infinity)
                VStack(spacing: 14) {
                    ForEach(exercise.right) { endpoint($0, left: false) }
                }.frame(maxWidth: .infinity)
            }
            Label(selectionPrompt, systemImage: error != nil ? "xmark.circle" : solved ? "checkmark.circle" : "hand.tap")
                .font(.subheadline)
                .foregroundStyle(error != nil ? Color.red : Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("matching-selection-prompt")
        }
        .task(id: pending) {
            guard let pair = pending else { return }
            // Briefly show both selected cards before showing the verdict.
            do { try await Task.sleep(for: .milliseconds(120)) } catch { return }
            guard !Task.isCancelled, pending == pair else { return }
            let correct = onPair(pair.left, pair.right)
            selection = nil
            pending = nil
            if !correct { error = pair }
        }
        .task(id: error) {
            guard let pair = error else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.1)) { errorPulse = true }
            do { try await Task.sleep(for: .milliseconds(120)) } catch { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { errorPulse = false }
            do { try await Task.sleep(for: .milliseconds(780)) } catch { return }
            guard !Task.isCancelled, error == pair else { return }
            error = nil
        }
    }

    private func endpoint(_ item: MatchItem, left: Bool) -> some View {
        let connected = left ? matches[item.id] : matches.first(where: { $0.value == item.id })?.key
        let paired = connected != nil
        let chosen = selection == Selection(id: item.id, isLeft: left) ||
            (pending.map { left ? $0.left == item.id : $0.right == item.id } ?? false)
        let wrong = error.map { left ? $0.left == item.id : $0.right == item.id } ?? false
        let connectedName = left
            ? exercise.right.first(where: { $0.id == connected })?.text
            : exercise.left.first(where: { $0.id == connected })?.text
        return Button {
            error = nil
            errorPulse = false
            if let previous = selection, previous.isLeft != left {
                pending = Pair(left: left ? item.id : previous.id, right: left ? previous.id : item.id)
            } else {
                selection = chosen ? nil : Selection(id: item.id, isLeft: left)
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: paired ? "checkmark.circle.fill" : wrong ? "xmark.circle.fill" : item.symbol)
                    .font(.system(size: 26))
                Text(item.text).font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(chosen ? Theme.paper : wrong ? Color.red : Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 96).padding(.horizontal, 10).padding(.vertical, 12)
            .background(chosen ? Theme.ink : wrong ? Color.red.opacity(0.12) : paired ? Color.green.opacity(0.12) : Theme.surface,
                        in: .rect(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(
                wrong ? Color.red : paired ? Color.green : chosen ? Theme.ink : Theme.line,
                lineWidth: chosen || wrong || paired ? 2 : 1))
            .offset(x: wrong && errorPulse && !reduceMotion ? 4 : 0)
        }
        .buttonStyle(.plain)
        .disabled(paired || pending != nil)
        .accessibilityLabel(item.text)
        .accessibilityValue(paired ? "配对正确：\(connectedName ?? "")" : wrong ? "不匹配，可以重新选择" :
            chosen ? "已选中，接着选择\(left ? "右侧" : "左侧")" : "未选择")
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier("match-\(left ? "left" : "right")-\(item.id)")
    }
}
