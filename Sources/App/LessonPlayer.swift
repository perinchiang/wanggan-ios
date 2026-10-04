import SwiftUI

struct LessonPlayer: View {
    let lesson: Lesson
    let onNext: (Lesson?) -> Void
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: LessonSession
    @State private var showExit = false
    @State private var showSources = false
    @State private var feedbackTick = 0

    init(lesson: Lesson, initialSession: LessonSession, onNext: @escaping (Lesson?) -> Void) {
        self.lesson = lesson
        self.onNext = onNext
        _session = State(initialValue: initialSession)
    }

    var body: some View {
        VStack(spacing: 0) {
            if session.stage != .complete { topBar }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Color.clear.frame(height: 0).id("lesson-top")
                        stageContent
                    }.padding(.horizontal, 22).padding(.bottom, 22)
                }
                .onChange(of: session.explanationIndex) { _, _ in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { proxy.scrollTo("explanation-bottom", anchor: .bottom) }
                }
                .task(id: scrollRequest) {
                    // Wait for the inserted bubble to finish laying out before finding its anchor.
                    // A newer message cancels this task, so quick taps cannot scroll to a stale one.
                    do { try await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 400)) }
                    catch { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) {
                        proxy.scrollTo(conversationScrollTarget ?? "lesson-top", anchor: .top)
                    }
                }
            }
        }
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sensoryFeedback(.selection, trigger: feedbackTick) { _, _ in store.hapticsEnabled }
        .onChange(of: session) { _, new in store.saveDraft(new) }
        .onChange(of: scenePhase) { _, phase in if phase != .active { store.saveDraft(session) } }
        .onAppear { store.saveDraft(session) }
        .confirmationDialog("稍后继续？", isPresented: $showExit, titleVisibility: .visible) {
            Button("保存进度并退出") { store.saveDraft(session); dismiss() }
            Button("继续学习", role: .cancel) { }
        } message: { Text("这次已经完成的步骤会留在本机。") }
        .sheet(isPresented: $showSources) { sourcesSheet }
    }

    private var topBar: some View {
        HStack(spacing: 20) {
            Button { showExit = true } label: { Image(systemName: "xmark").font(.title3).frame(width: 44, height: 44) }
                .accessibilityLabel("退出小节").accessibilityIdentifier("exit-lesson")
            ThinProgress(value: Double(session.stage.rawValue + 1) / 4)
            Text("\(session.stage.rawValue + 1) / 4").font(.caption.monospacedDigit())
        }.padding(.horizontal, 14).padding(.vertical, 10)
    }

    @ViewBuilder private var stageContent: some View {
        switch session.stage {
        case .question:
            questionContent(lesson.question, challenge: false)
        case .explanation:
            TutorBubble(text: "沿着数据走一遍，就清楚了。")
            ConceptIllustration(lesson: lesson, animated: true)
            ForEach(Array(lesson.explanation.prefix(session.explanationIndex + 1)), id: \.self) { paragraph in
                ConversationBubble(text: paragraph)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Button { showSources = true } label: { Label("看看知识来源", systemImage: "book.closed").font(.caption).frame(minHeight: 44) }
                .foregroundStyle(Theme.muted).id("explanation-bottom")
        case .matching:
            TutorBubble(text: "换个方式，试着连一连。")
            Text(lesson.matching.prompt).font(.body).foregroundStyle(Theme.muted)
            MatchingView(exercise: lesson.matching, session: $session)
            if session.matchingSubmitted {
                feedbackCard(title: session.matchingSolved ? "连起来了" : "再想一小步",
                             text: session.matchingSolved ? lesson.matching.explanation : "还有连线不符合刚才的机制。重新选择左、右两项就能修改；每项只能连接一次。",
                             correct: session.matchingSolved)
            }
        case .challenge:
            Text("换个情况，你还会判断吗？").font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
            questionContent(lesson.challenge, challenge: true)
        case .complete:
            CompletionView(lesson: lesson, earnedXP: session.earnedXP ?? 0,
                           totalXP: store.ledger.totalXP, level: store.ledger.level)
        }
    }

    private func questionContent(_ question: Question, challenge: Bool) -> some View {
        let selected = challenge ? session.challengeAnswer : session.selectedAnswer
        let submitted = challenge ? session.challengeSubmitted : session.answerSubmitted
        let ready = session.sceneIsComplete(for: question, challenge: challenge)
        return VStack(alignment: .leading, spacing: 18) {
            QuestionConversation(question: question, lesson: lesson,
                                 step: session.sceneStep(for: question, challenge: challenge), challenge: challenge)
            if ready {
                ForEach(question.options) { option in
                    Button {
                        if challenge { session.challengeAnswer = option.id }
                        else { session.selectedAnswer = option.id }
                        feedbackTick += 1
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: selected == option.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3).foregroundStyle(selected == option.id ? Theme.ink : Theme.muted)
                            Text(option.text).font(.body.weight(.medium)).multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .background(selected == option.id ? Theme.lime.opacity(0.22) : Theme.surface, in: .rect(cornerRadius: 17))
                            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(selected == option.id ? Theme.ink : Theme.line, lineWidth: selected == option.id ? 1.5 : 1))
                    }
                    .buttonStyle(PressStyle()).disabled(submitted)
                    .accessibilityAddTraits(selected == option.id ? .isSelected : [])
                    .accessibilityIdentifier("\(challenge ? "challenge" : "question")-option-\(option.id)")
                }
                if submitted, let answer = question.options.first(where: { $0.id == selected }) {
                    feedbackCard(title: selected == question.correctID ? "判断正确" : "这里值得再想想", text: answer.feedback,
                                 correct: selected == question.correctID)
                    if challenge && !session.challengeSolved {
                        Text("一点提示：\(question.hint)").font(.subheadline).foregroundStyle(Theme.muted).lineSpacing(4)
                    }
                } else {
                    Text(challenge ? "用刚才的机制，判断这个新场景。" : "先做出判断，答错也能学会。")
                        .font(.footnote).foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
                }
            } else {
                Text("\(min(session.sceneStep(for: question, challenge: challenge) + 1, question.scene.count)) / \(question.scene.count) 条消息")
                    .font(.caption).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity).accessibilityIdentifier("scene-progress")
            }
        }
    }

    private var activeQuestion: Question? {
        switch session.stage {
        case .question: return lesson.question
        case .challenge: return lesson.challenge
        default: return nil
        }
    }

    private var conversationScrollTarget: String? {
        guard let question = activeQuestion else { return nil }
        let challenge = session.stage == .challenge
        let prefix = challenge ? "challenge" : "question"
        let step = session.sceneStep(for: question, challenge: challenge)
        if step >= question.scene.count { return "\(prefix)-prompt" }
        return "\(prefix)-scene-\(question.scene[step].id)"
    }

    private var scrollRequest: String { conversationScrollTarget ?? "stage-\(session.stage.rawValue)" }

    private func feedbackCard(title: String, text: String, correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: correct ? "checkmark.circle.fill" : "lightbulb")
                .font(.headline)
            Text(text).font(.subheadline).lineSpacing(5)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .background(correct ? Theme.lime.opacity(0.35) : Theme.line.opacity(0.4), in: .rect(cornerRadius: 18))
            .accessibilityIdentifier("answer-feedback")
    }

    private var bottomBar: some View {
        VStack(spacing: 6) {
            PrimaryButton(title: buttonTitle, enabled: buttonEnabled,
                          symbol: session.stage == .complete ? "arrow.right" : "",
                          identifier: session.stage == .complete ? "continue-learning" : "primary-action", action: performAction)
            if session.stage == .complete {
                Button("今天到这里") { dismiss() }
                    .font(.subheadline).frame(minHeight: 44).accessibilityIdentifier("finish-session")
            }
        }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 8)
            .background(Theme.paper)
    }

    private var buttonTitle: String {
        if let question = activeQuestion, !session.sceneIsComplete(for: question, challenge: session.stage == .challenge) {
            return session.sceneStep(for: question, challenge: session.stage == .challenge) + 1 == question.scene.count ? "我来判断" : "继续"
        }
        switch session.stage {
        case .question: return session.answerSubmitted ? "看看为什么" : "确认答案"
        case .explanation: return session.explanationIndex + 1 < lesson.explanation.count ? "继续看一小步" : "试着连一连"
        case .matching: return session.matchingSolved ? "挑战一个新场景" : "检查连线"
        case .challenge: return session.challengeSolved ? "完成探索" : session.challengeSubmitted ? "再试一次" : "确认判断"
        case .complete: return nextLesson == nil ? "回到学习路线" : "继续探索"
        }
    }

    private var buttonEnabled: Bool {
        if let question = activeQuestion, !session.sceneIsComplete(for: question, challenge: session.stage == .challenge) { return true }
        switch session.stage {
        case .question: return session.selectedAnswer != nil
        case .matching: return session.matches.count == lesson.matching.left.count && (!session.matchingSubmitted || session.matchingSolved)
        case .challenge: return session.challengeAnswer != nil
        default: return true
        }
    }

    private var nextLesson: Lesson? {
        guard let index = store.lessons.firstIndex(where: { $0.id == lesson.id }), index + 1 < store.lessons.count else { return nil }
        return store.lessons[index + 1]
    }

    private func performAction() {
        feedbackTick += 1
        if let question = activeQuestion, !session.sceneIsComplete(for: question, challenge: session.stage == .challenge) {
            withAnimation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.85)) {
                session.revealNextScene(for: question, challenge: session.stage == .challenge)
            }
            return
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
            switch session.stage {
            case .question:
                if session.answerSubmitted { session.advance(lesson: lesson) }
                else { session.submitQuestion(lesson.question) }
            case .explanation: session.advance(lesson: lesson)
            case .matching:
                if session.matchingSolved { session.advance(lesson: lesson) }
                else { session.submitMatching(lesson.matching) }
            case .challenge:
                if session.challengeSolved {
                    session.advance(lesson: lesson)
                    session.earnedXP = store.finish(session)
                } else if session.challengeSubmitted { session.retryChallenge(question: lesson.challenge) }
                else { session.submitChallenge(lesson.challenge) }
            case .complete:
                if let nextLesson { onNext(nextLesson) } else { dismiss() }
            }
        }
    }

    private var sourcesSheet: some View {
        NavigationStack {
            List {
                Section("本节知识来源") {
                    ForEach(lesson.sources, id: \.self) { source in
                        if let url = URL(string: source) { Link(source, destination: url).font(.footnote) }
                    }
                }
                Section { Text("课程采用原创场景与讲解。请留意每道题的前提；真实网络还可能受 VLAN、路由策略、防火墙等因素影响。") }
            }.navigationTitle("知识来源")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showSources = false } } }
        }
    }
}
