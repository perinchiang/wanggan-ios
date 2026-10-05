import SwiftUI

struct LessonPlayer: View {
    let lesson: Lesson
    let initialSession: LessonSession
    let onNext: (Lesson?) -> Void

    var body: some View {
        if ["gateway", "subnet", "arp", "hop"].contains(lesson.id) {
            StepLessonPlayer(lesson: lesson, initialSession: initialSession, onNext: onNext)
        } else {
            StageLessonPlayer(lesson: lesson, initialSession: initialSession, onNext: onNext)
        }
    }
}

struct StepLessonPlayer: View {
    let lesson: Lesson
    let onNext: (Lesson?) -> Void
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private let plan: LessonPlan
    @State private var session: StepSession
    @State private var earnedXP: Int?
    @State private var showExit = false
    @State private var showSources = false
    @State private var feedbackTick = 0

    init(lesson: Lesson, initialSession: LessonSession, onNext: @escaping (Lesson?) -> Void) {
        self.lesson = lesson
        self.onNext = onNext
        self.plan = LessonPlan(lesson: lesson)
        _session = State(initialValue: StepSession(lesson: lesson, from: initialSession))
    }

    private var isComplete: Bool { plan.isComplete(session) }

    var body: some View {
        VStack(spacing: 0) {
            if !isComplete { topBar }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Color.clear.frame(height: 0).id("lesson-top")
                        stepContent
                    }.padding(.horizontal, 22).padding(.bottom, 22)
                }
                .onChange(of: session.stepIndex) { _, _ in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { proxy.scrollTo("step-bottom", anchor: .bottom) }
                }
                .task(id: scrollRequest) {
                    do { try await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 400)) }
                    catch { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) {
                        proxy.scrollTo(feedbackScrollTarget ?? conversationScrollTarget ?? "lesson-top",
                                       anchor: feedbackScrollTarget == nil ? .top : .bottom)
                    }
                }
            }
        }
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sensoryFeedback(.selection, trigger: feedbackTick) { _, _ in store.hapticsEnabled }
        .onChange(of: session) { _, new in store.saveDraft(new.stageSession(lesson: lesson)) }
        .onChange(of: scenePhase) { _, phase in if phase != .active { store.saveDraft(session.stageSession(lesson: lesson)) } }
        .onAppear { store.saveDraft(session.stageSession(lesson: lesson)) }
        .confirmationDialog("稍后继续？", isPresented: $showExit, titleVisibility: .visible) {
            Button("保存进度并退出") { store.saveDraft(session.stageSession(lesson: lesson)); dismiss() }
            Button("继续学习", role: .cancel) { }
        } message: { Text("这次已经完成的步骤会留在本机。") }
        .sheet(isPresented: $showSources) { sourcesSheet }
    }

    private var topBar: some View {
        HStack(spacing: 20) {
            Button { showExit = true } label: { Image(systemName: "xmark").font(.title3).frame(width: 44, height: 44) }
                .accessibilityLabel("退出小节").accessibilityIdentifier("exit-lesson")
            ThinProgress(value: Double(min(session.stepIndex + 1, plan.steps.count)) / Double(plan.steps.count))
            Text("\(min(session.stepIndex + 1, plan.steps.count)) / \(plan.steps.count)").font(.caption.monospacedDigit())
        }.padding(.horizontal, 14).padding(.vertical, 10)
    }

    @ViewBuilder private var stepContent: some View {
        if isComplete {
            CompletionView(lesson: lesson, earnedXP: earnedXP ?? 0,
                           totalXP: store.ledger.totalXP, level: store.ledger.level)
        } else if let step = plan.step(at: session.stepIndex) {
            switch step.kind {
            case .conversation, .question:
                questionPhase
            case .diagram, .text:
                explanationPhase
            case .matching:
                TutorBubble(text: "换个方式，试着连一连。")
                Text(lesson.matching.prompt).font(.body).foregroundStyle(Theme.muted)
                MatchingView(exercise: lesson.matching, matches: $session.matches,
                             matchingSubmitted: $session.matchingSubmitted, matchingSolved: $session.matchingSolved)
                if session.matchingSubmitted {
                    feedbackCard(title: session.matchingSolved ? "连起来了" : "再想一小步",
                                 text: session.matchingSolved ? lesson.matching.explanation : "还有连线不符合刚才的机制。重新选择左、右两项就能修改；每项只能连接一次。",
                                 correct: session.matchingSolved)
                }
            case .summary:
                ConversationBubble(text: lesson.takeaway)
            }
        }
        Color.clear.frame(height: 0).id("step-bottom")
    }

    @ViewBuilder private var explanationPhase: some View {
        TutorBubble(text: "沿着数据走一遍，就清楚了。")
        ConceptIllustration(lesson: lesson, animated: true)
        if visibleTextCount > 0 {
            ForEach(Array(lesson.explanation.prefix(visibleTextCount)), id: \.self) { paragraph in
                ConversationBubble(text: paragraph)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        Button { showSources = true } label: { Label("看看知识来源", systemImage: "book.closed").font(.caption).frame(minHeight: 44) }
            .foregroundStyle(Theme.muted).id("explanation-bottom")
    }

    private var visibleTextCount: Int {
        guard let step = plan.step(at: session.stepIndex) else { return 0 }
        switch step.kind {
        case .diagram: return 0
        case .text: return min(session.stepIndex - plan.questionIndex - 1, lesson.explanation.count)
        default: return 0
        }
    }

    @ViewBuilder private var questionPhase: some View {
        let challenge = session.stepIndex > plan.matchingIndex
        let question = challenge ? lesson.challenge : lesson.question
        let sceneStep = challenge
            ? min(session.stepIndex - plan.matchingIndex - 1, plan.challengeSceneCount)
            : min(session.stepIndex, plan.questionSceneCount)
        questionContent(question, challenge: challenge, sceneStep: sceneStep)
    }

    private func questionContent(_ question: Question, challenge: Bool, sceneStep: Int) -> some View {
        let selected = challenge ? session.challengeAnswer : session.selectedAnswer
        let submitted = challenge ? session.challengeSubmitted : session.answerSubmitted
        let ready = sceneStep >= question.scene.count
        return VStack(alignment: .leading, spacing: 18) {
            QuestionConversation(question: question, lesson: lesson, step: sceneStep, challenge: challenge)
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
                        .id("answer-feedback")
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    if challenge && !session.challengeSolved {
                        Text("一点提示：\(question.hint)").font(.subheadline).foregroundStyle(Theme.muted).lineSpacing(4)
                    }
                } else {
                    Text(challenge ? "用刚才的机制，判断这个新场景。" : "先做出判断，答错也能学会。")
                        .font(.footnote).foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
                }
            } else {
                Text("\(min(sceneStep + 1, question.scene.count)) / \(question.scene.count) 条消息")
                    .font(.caption).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity).accessibilityIdentifier("scene-progress")
            }
        }
    }

    private var conversationScrollTarget: String? {
        guard let step = plan.step(at: session.stepIndex) else { return nil }
        switch step.kind {
        case .conversation:
            if case .conversation(let message) = step.payload {
                return session.stepIndex < plan.questionIndex ? "question-scene-\(message.id)" : "challenge-scene-\(message.id)"
            }
        case .question:
            return session.stepIndex == plan.questionIndex ? "question-prompt" : "challenge-prompt"
        default: break
        }
        return nil
    }

    private var feedbackScrollTarget: String? {
        guard plan.step(at: session.stepIndex)?.kind == .question else { return nil }
        let submitted = session.stepIndex == plan.challengeIndex ? session.challengeSubmitted : session.answerSubmitted
        return submitted ? "answer-feedback" : nil
    }

    private var scrollRequest: String {
        if let feedbackScrollTarget { return "\(session.stepIndex)-\(feedbackScrollTarget)" }
        return conversationScrollTarget ?? "step-\(session.stepIndex)"
    }

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
                          symbol: isComplete ? "arrow.right" : "",
                          identifier: isComplete ? "continue-learning" : "primary-action", action: performAction)
            if isComplete {
                Button("今天到这里") { dismiss() }
                    .font(.subheadline).frame(minHeight: 44).accessibilityIdentifier("finish-session")
            }
        }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 8)
            .background(Theme.paper)
    }

    private var buttonTitle: String {
        guard let step = plan.step(at: session.stepIndex) else { return "继续" }
        switch step.kind {
        case .conversation:
            return plan.step(at: session.stepIndex + 1)?.kind == .question ? "我来判断" : "继续"
        case .question:
            if session.stepIndex == plan.challengeIndex {
                return session.challengeSolved ? "完成探索" : session.challengeSubmitted ? "再试一次" : "确认判断"
            }
            return session.answerSubmitted ? "看看为什么" : "确认答案"
        case .diagram:
            return lesson.explanation.isEmpty ? "试着连一连" : "继续看一小步"
        case .text:
            return plan.step(at: session.stepIndex + 1)?.kind == .matching ? "试着连一连" : "继续看一小步"
        case .matching:
            return session.matchingSolved ? "挑战一个新场景" : "检查连线"
        case .summary:
            return nextLesson == nil ? "回到学习路线" : "继续探索"
        }
    }

    private var buttonEnabled: Bool {
        guard let step = plan.step(at: session.stepIndex) else { return true }
        switch step.kind {
        case .conversation, .diagram, .text, .summary:
            return true
        case .question:
            if session.stepIndex == plan.challengeIndex { return session.challengeAnswer != nil }
            return session.selectedAnswer != nil
        case .matching:
            return session.matches.count == lesson.matching.left.count && (!session.matchingSubmitted || session.matchingSolved)
        }
    }

    private var nextLesson: Lesson? {
        guard let next = store.currentLesson, store.ledger.lessons[next.id] == nil else { return nil }
        return next
    }

    private func performAction() {
        feedbackTick += 1
        guard let step = plan.step(at: session.stepIndex) else { return }
        switch step.kind {
        case .conversation:
            withAnimation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.85)) {
                plan.advance(&session)
            }
        case .question:
            if session.stepIndex == plan.challengeIndex {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                    if session.challengeSolved {
                        plan.advance(&session)
                        earnedXP = store.finish(session.stageSession(lesson: lesson))
                    } else if session.challengeSubmitted {
                        plan.retryChallenge(in: &session)
                    } else {
                        plan.submitChallenge(session.challengeAnswer ?? "", in: &session)
                    }
                }
            } else {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                    if session.answerSubmitted { plan.advance(&session) }
                    else { plan.submitAnswer(session.selectedAnswer ?? "", in: &session) }
                }
            }
        case .diagram, .text:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { plan.advance(&session) }
        case .matching:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                if session.matchingSolved { plan.advance(&session) }
                else { plan.submitMatching(in: &session) }
            }
        case .summary:
            if let nextLesson { onNext(nextLesson) } else { dismiss() }
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
