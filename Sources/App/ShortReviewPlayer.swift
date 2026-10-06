import SwiftUI

struct ShortReviewPlayer: View {
    let item: ReviewItem
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: ShortReviewSession
    @State private var earnedXP: Int?
    @State private var showExit = false
    @State private var discardingSession = false

    init(item: ReviewItem, initialSession: ShortReviewSession) {
        self.item = item
        _session = State(initialValue: initialSession)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { showExit = true } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel("退出短复习").accessibilityIdentifier("exit-short-review")
                Spacer()
                Text("一题短复习").font(.headline)
                Spacer()
                Text("1 / 1").font(.caption.monospacedDigit())
            }.padding(.horizontal, 14).padding(.vertical, 8)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(item.objective).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                        if let earnedXP {
                            completion(earnedXP)
                        } else {
                            Text(item.scene).font(.body).lineSpacing(5)
                            Text(item.prompt).font(.title3.bold())
                            ForEach(item.options) { option in
                                Button { session.select(option.id, item: item) } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: session.selectedAnswer == option.id ? "checkmark.circle.fill" : "circle")
                                        Text(option.text).frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .font(.body).padding(.horizontal, 12).padding(.vertical, 18)
                                    .background(session.selectedAnswer == option.id ? Theme.lime.opacity(0.35) : Theme.surface,
                                                in: .rect(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line))
                                }.buttonStyle(PressStyle()).disabled(session.submitted)
                                    .accessibilityAddTraits(session.selectedAnswer == option.id ? .isSelected : [])
                                    .accessibilityIdentifier("short-option-\(option.id)")
                            }
                            if !session.submitted {
                                Button("给我一点提示") { session.usedHint = true }
                                    .frame(minHeight: 44).accessibilityIdentifier("short-hint")
                            }
                            if session.usedHint { TutorBubble(text: item.hint) }
                            if session.submitted, let option = item.options.first(where: { $0.id == session.selectedAnswer }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(session.solved ? "判断对了" : "这里值得再想想").font(.headline)
                                    Text(session.solved ? item.explanation : option.feedback).font(.body).lineSpacing(5)
                                    if session.solved {
                                        Text(session.independent ? "这次是独立判断。" : "这次在帮助下完成，下次换个场景再试。")
                                            .font(.subheadline).foregroundStyle(Theme.muted)
                                    }
                                }.padding(18).background(Theme.line.opacity(0.4), in: .rect(cornerRadius: 20))
                                    .accessibilityIdentifier("short-feedback").id("short-feedback")
                            }
                        }
                    }.padding(22)
                }
                .task(id: session.attempts.count) {
                    guard session.submitted else { return }
                    do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                        proxy.scrollTo("short-feedback", anchor: .bottom)
                    }
                }
            }
        }
        .background(Theme.paper).foregroundStyle(Theme.ink)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: actionTitle, enabled: earnedXP != nil || session.submitted || session.selectedAnswer != nil,
                          identifier: "short-primary") { performAction() }
                .padding(.horizontal, 22).padding(.vertical, 12).background(Theme.paper)
        }
        .onAppear { if !discardingSession { store.saveShortDraft(session) } }
        .onChange(of: session) { _, new in
            if !discardingSession { store.saveShortDraft(new) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && !discardingSession { store.saveShortDraft(session) }
        }
        .confirmationDialog("确认退出？", isPresented: $showExit, titleVisibility: .visible) {
            Button("确定退出", role: .destructive) {
                discardingSession = true
                store.discardShortDraft(session)
                dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: { Text("未完成的复习将从头开始，已提交的判断记录保留。") }
    }

    private var actionTitle: String {
        if earnedXP != nil { return "回到复习" }
        if session.solved { return "完成短复习" }
        return session.submitted ? "再判断一次" : "确认判断"
    }

    private func performAction() {
        if earnedXP != nil { dismiss() }
        else if session.solved { earnedXP = store.finishShortReview(session) }
        else if session.submitted { session.retry() }
        else { session.submit(item: item) }
    }

    private func completion(_ reward: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            PacketMascot(size: 72, celebrating: true)
            Text("这次判断，记下来了。").font(.title2.bold())
            Text(reward > 0 ? "+\(reward) XP" : "今天这节课的经验已领取，判断记录仍会更新。")
                .font(.headline).accessibilityIdentifier("short-reward")
            Text(store.ledger.evidenceStatus(for: item.knowledgePointID).rawValue)
                .font(.body).accessibilityIdentifier("short-evidence")
            Text("一次答对只是一次证据；之后再换个场景检验。").font(.subheadline).foregroundStyle(Theme.muted)
        }.padding(.vertical, 20)
    }
}
