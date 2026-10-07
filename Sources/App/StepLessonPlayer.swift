import SwiftUI

struct StepLessonPlayer: View {
    let lesson: Lesson
    let onNext: (Lesson?) -> Void
    let usesStaticPresentation: Bool
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { systemReduceMotion || usesStaticPresentation }
    @Environment(\.scenePhase) private var scenePhase
    private let plan: LessonPlan
    @State private var session: StepSession
    @State private var earnedXP: Int?
    @State private var showExit = false
    @State private var discardingSession = false
    @State private var showSources = false
    @State private var feedbackTick = 0
    @State private var topologyReplayID = 0

    init(lesson: Lesson, initialSession: LessonSession, usesStaticPresentation: Bool = false, onNext: @escaping (Lesson?) -> Void) {
        self.lesson = lesson
        self.onNext = onNext
        self.usesStaticPresentation = usesStaticPresentation
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
                .task(id: scrollRequest) {
                    do { try await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 400)) }
                    catch { return }
                    let target = feedbackScrollTarget ?? conversationScrollTarget ?? explanationScrollTarget ?? "lesson-top"
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) {
                        proxy.scrollTo(target, anchor: feedbackScrollTarget == nil ? .top : .bottom)
                    }
                }
            }
        }
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sensoryFeedback(.selection, trigger: feedbackTick) { _, _ in store.hapticsEnabled }
        .onChange(of: session) { _, new in
            if !discardingSession { store.saveDraft(new.stageSession(lesson: lesson)) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && !discardingSession { store.saveDraft(session.stageSession(lesson: lesson)) }
        }
        .onAppear {
            guard !discardingSession else { return }
            if isComplete { earnedXP = store.finish(session.stageSession(lesson: lesson)) }
            else { store.saveDraft(session.stageSession(lesson: lesson)) }
        }
        .confirmationDialog("确认退出？", isPresented: $showExit, titleVisibility: .visible) {
            Button("确定退出", role: .destructive) {
                discardingSession = true
                store.discardDraft(session.stageSession(lesson: lesson))
                dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: { Text("退出后，这次未完成的小节将从头开始。") }
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
                if let page = plan.answerExplanation(at: session.stepIndex) {
                    VStack(alignment: .leading, spacing: 18) {
                        if let term = page.termIntroduction {
                            TermIntroductionCard(term: term)
                        } else if let network = page.homeNetwork {
                            HomeNetworkDiagram(spec: network)
                        } else if let diagram = page.diagram {
                            DevicePortsDiagram(spec: diagram)
                        }
                        ConversationBubble(text: page.text, highlightedTerms: ["光猫", "路由器", "光纤", "FTTR", "WAN", "LAN"])
                        if let diagram = page.diagram, page.homeNetwork != nil || page.termIntroduction != nil {
                            DisclosureGroup("看看设备接口") {
                                DevicePortsDiagram(spec: diagram).padding(.top, 10)
                            }
                            .id(page.id)
                            .font(.subheadline).tint(Theme.ink)
                            .accessibilityIdentifier("device-ports-details")
                        }
                    }
                    .id("answer-explanation-anchor")
                    .accessibilityIdentifier("answer-explanation-\(page.id)")
                } else {
                    explanationPhase
                }
            case .matching:
                if lesson.usesMatching {
                    TutorBubble(text: "找找哪些意思对应。")
                    Text(lesson.matching.prompt).font(.body).foregroundStyle(Theme.muted)
                    MatchingView(exercise: lesson.matching, matches: session.matches, onPair: { left, right in
                        plan.matchPair(left, to: right, in: &session)
                    }, usesStaticPresentation: usesStaticPresentation)
                    .id(step.id)
                    if session.matchingSolved {
                        feedbackCard(title: "配对完成", text: lesson.matching.explanation, correct: true)
                    }
                }
            case .summary:
                ConversationBubble(text: lesson.takeaway)
            }
        }
        Color.clear.frame(height: 0).id("step-bottom")
    }

    @ViewBuilder private var explanationPhase: some View {
        if let topology = lesson.topology {
            VStack(alignment: .leading, spacing: 14) {
                Text("观察 \(visibleTextCount + 1) / \(lesson.explanation.count + 1)")
                    .font(.caption).foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("topology-stage")
                TopologyDiagram(spec: topology, stage: visibleTextCount + 1,
                                animated: !reduceMotion, replayID: topologyReplayID)
            }.id("topology-anchor")
        }
        if visibleTextCount > 0 {
            if lesson.topology != nil {
                let paragraph = lesson.explanation[min(visibleTextCount, lesson.explanation.count) - 1]
                ConversationBubble(text: paragraph, highlightedTerms: topologyKeywords(in: paragraph))
                    .accessibilityIdentifier("topology-explanation-text")
                if let topology = lesson.topology, visibleTextCount + 1 >= topology.flowStage {
                    Button("再看一次数据怎么走") { topologyReplayID += 1 }
                        .font(.subheadline).frame(minHeight: 44)
                        .accessibilityIdentifier("topology-replay")
                }
            } else {
                ForEach(Array(lesson.explanation.prefix(visibleTextCount)), id: \.self) { paragraph in
                    ConversationBubble(text: paragraph, highlightedTerms: topologyKeywords(in: paragraph))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        Button { showSources = true } label: { Label("看看知识来源", systemImage: "book.closed").font(.caption).frame(minHeight: 44) }
            .foregroundStyle(Theme.muted)
            .accessibilityIdentifier("explanation-sources")
            .id("explanation-bottom")
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
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: selected == option.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3).foregroundStyle(selected == option.id ? Theme.ink : Theme.muted)
                            Text(option.text).font(.body.weight(.medium)).multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.padding(.horizontal, 12).padding(.vertical, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

    private var explanationScrollTarget: String? {
        if plan.answerExplanation(at: session.stepIndex) != nil { return "answer-explanation-anchor" }
        guard lesson.topology != nil, let kind = plan.step(at: session.stepIndex)?.kind,
              kind == .diagram || kind == .text else { return nil }
        return "topology-anchor"
    }

    private var feedbackScrollTarget: String? {
        guard plan.step(at: session.stepIndex)?.kind == .question else { return nil }
        let submitted = session.stepIndex == plan.challengeIndex ? session.challengeSubmitted : session.answerSubmitted
        return submitted ? "answer-feedback" : nil
    }

    private var scrollRequest: String {
        if plan.answerExplanation(at: session.stepIndex) != nil { return "answer-explanation-\(session.stepIndex)" }
        if explanationScrollTarget != nil { return "topology-explanation-\(session.stepIndex)" }
        if let feedbackScrollTarget { return "\(session.stepIndex)-\(feedbackScrollTarget)" }
        return conversationScrollTarget ?? "step-\(session.stepIndex)"
    }

    private func topologyKeywords(in paragraph: String) -> [String] {
        guard let topology = lesson.topology else { return [] }
        let terms = topology.nodes.map { node in
            node.label.contains("光纤") ? "光纤" : node.label
        }
        return terms.filter { paragraph.contains($0) }
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
            if plan.canRevisitPreviousExplanation(session) {
                Button("上一步") { plan.revisitPreviousExplanation(&session) }
                    .font(.subheadline).frame(minHeight: 44)
                    .accessibilityIdentifier("teaching-previous")
            }
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
                if session.challengeSolved {
                    return lesson.challenge.answerExplanation == nil ? "完成探索" : "看看接口有什么不同"
                }
                return session.challengeSubmitted ? "再试一次" : "确认判断"
            }
            return session.answerSubmitted ? "看看为什么" : "确认答案"
        case .diagram:
            return lesson.explanation.isEmpty ? "找找对应关系" : "继续看一小步"
        case .text:
            if plan.answerExplanation(at: session.stepIndex) != nil {
                return session.stepIndex + 1 == plan.summaryIndex ? "完成探索" : "继续看一小步"
            }
            return plan.step(at: session.stepIndex + 1)?.kind == .matching ? "找找对应关系" : "继续看一小步"
        case .matching:
            return "继续"
        case .summary:
            return nextLesson == nil ? "回到学习路线" : "继续探索"
        }
    }

    private var buttonEnabled: Bool {
        guard let step = plan.step(at: session.stepIndex) else { return true }
        switch step.kind {
        case .conversation, .text, .summary:
            return true
        case .diagram:
            return plan.canAdvance(session)
        case .question:
            if session.stepIndex == plan.challengeIndex { return session.challengeAnswer != nil }
            return session.selectedAnswer != nil
        case .matching:
            return session.matchingSolved
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
                        if isComplete { earnedXP = store.finish(session.stageSession(lesson: lesson)) }
                    } else if session.challengeSubmitted {
                        plan.retryChallenge(in: &session)
                    } else {
                        plan.submitChallenge(session.challengeAnswer ?? "", in: &session)
                    }
                }
            } else {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                    if session.answerSubmitted {
                        plan.advance(&session)
                    }
                    else { plan.submitAnswer(session.selectedAnswer ?? "", in: &session) }
                }
            }
        case .diagram:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                plan.advance(&session)
            }
        case .text:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                plan.advance(&session)
                if isComplete { earnedXP = store.finish(session.stageSession(lesson: lesson)) }
            }
        case .matching:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                if session.matchingSolved { plan.advance(&session) }
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
