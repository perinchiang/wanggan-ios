import SwiftUI

struct StepLessonPlayer: View {
    let lesson: Lesson
    let onNext: (Lesson?) -> Void
    let usesStaticPresentation: Bool
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { systemReduceMotion || usesStaticPresentation }
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    private let plan: LessonPlan
    @State private var session: StepSession
    @State private var earnedXP: Int?
    @State private var showExit = false
    @State private var showSources = false
    @State private var feedbackTick = 0
    @State private var visualHeight: CGFloat = 340
    @State private var visualFailed = false
    @State private var visualReloadID = UUID()

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
        .onChange(of: session) { _, new in store.saveDraft(new.stageSession(lesson: lesson)) }
        .onChange(of: scenePhase) { _, phase in if phase != .active { store.saveDraft(session.stageSession(lesson: lesson)) } }
        .onAppear {
            if isComplete { earnedXP = store.finish(session.stageSession(lesson: lesson)) }
            else { store.saveDraft(session.stageSession(lesson: lesson)) }
        }
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
        if let foundation = lesson.ipv4Foundation {
            IPv4FoundationPanel(configuration: foundation, usesStaticPresentation: usesStaticPresentation, progress: Binding(
                get: { session.ipv4FoundationProgress ?? IPv4FoundationProgress() },
                set: { session.ipv4FoundationProgress = $0 }
            ))
        } else if let mask = lesson.subnetMaskIntroduction {
            SubnetMaskIntroductionPanel(configuration: mask, usesStaticPresentation: usesStaticPresentation, progress: Binding(
                get: { session.subnetMaskProgress ?? SubnetMaskProgress() },
                set: { session.subnetMaskProgress = $0 }
            ))
        } else if let introduction = lesson.ipv4Introduction {
            IPv4IntroductionPanel(introduction: introduction, progress: Binding(
                get: { session.ipv4IntroductionProgress ?? IPv4IntroductionProgress() },
                set: { session.ipv4IntroductionProgress = $0 }
            ), fontScale: visualFontScale)
        } else if session.stepIndex == plan.questionIndex + 1, let visual = lesson.ipv4Visual {
            ipv4VisualPanel(visual)
        } else {
            ConceptIllustration(lesson: lesson, animated: true, stage: visibleTextCount + 1)
                .id(lesson.topology == nil ? "concept-illustration" : "topology-anchor")
        }
        if visibleTextCount > 0 {
            ForEach(Array(lesson.explanation.prefix(visibleTextCount)), id: \.self) { paragraph in
                ConversationBubble(text: paragraph, emphasis: topologyEmphasis(in: paragraph))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        Button { showSources = true } label: { Label("看看知识来源", systemImage: "book.closed").font(.caption).frame(minHeight: 44) }
            .foregroundStyle(Theme.muted)
            .accessibilityIdentifier("explanation-sources")
            .id("explanation-bottom")
    }

    @ViewBuilder private func ipv4VisualPanel(_ visual: IPv4VisualLesson) -> some View {
        let phase = min(max(session.ipv4VisualPhase ?? 0, 0), 1)
        let example = visual.examples[phase]
        Text(phase == 0 ? "先看 /24 怎样把地址分成两部分。" : "换一条地址：点选网络部分结束的那个字节。")
            .font(.subheadline).foregroundStyle(Theme.muted)
        if !visualFailed {
            IPv4AddressVisualWebView(
                example: example, selectedOctet: session.ipv4SelectedOctet,
                solved: session.ipv4VisualSolved ?? false, theme: colorScheme,
                fontScale: visualFontScale,
                reduceMotion: reduceMotion, isActive: scenePhase == .active,
                onSelect: { selected in selectIPv4Boundary(selected) },
                onHeight: { height in if abs(visualHeight - height) > 2 { visualHeight = height } },
                onFailure: { visualFailed = true }
            )
            .id(visualReloadID)
            .frame(height: visualHeight)
            .accessibilityIdentifier("ipv4-visual")
        } else {
            ipv4VisualFallback(example: example)
            Button("重试动态图") { visualFailed = false; visualReloadID = UUID() }
                .font(.subheadline).frame(minHeight: 44)
        }
        if phase == 1, session.ipv4VisualSubmitted == true {
            feedbackCard(
                title: session.ipv4VisualSolved == true ? "分界找对了" : "再数一数网络位",
                text: session.ipv4VisualSolved == true
                    ? "前 \(example.prefix) 位属于网络部分，所以边界在第 \(example.prefix / 8) 个字节后。"
                    : "/\(example.prefix) 表示从左往右数 \(example.prefix) 位；一个字节有 8 位。",
                correct: session.ipv4VisualSolved == true
            )
            .id("ipv4-feedback")
        }
    }

    private func ipv4VisualFallback(example: IPv4VisualExample) -> some View {
        Surface {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(example.ip)/\(example.prefix)").font(.headline.monospaced())
                if let address = IPv4AddressValue(ip: example.ip, prefix: example.prefix) {
                    ForEach(0..<4, id: \.self) { index in
                        let octet = Int(address.octets[index])
                        let bits = address.binaryOctets[index]
                        VStack(alignment: .leading, spacing: 6) {
                            Text("第 \(index + 1) 个字节：\(octet) = \(bits)")
                                .font(.subheadline.monospaced())
                            if example.mode == .practice && session.ipv4VisualSolved != true {
                                Button("选第 \(index + 1) 个字节后") { selectIPv4Boundary(index + 1) }
                                    .accessibilityAddTraits(session.ipv4SelectedOctet == index + 1 ? .isSelected : [])
                                    .accessibilityIdentifier("ipv4-fallback-boundary-\(index + 1)")
                            }
                        }
                    }
                    if example.mode == .explain || session.ipv4VisualSolved == true {
                        Text("前 \(example.prefix) 位是网络部分；网络地址是 \(address.networkAddress)/\(example.prefix)。")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private func selectIPv4Boundary(_ selected: Int) {
        guard (session.ipv4VisualPhase ?? 0) == 1, session.ipv4VisualSolved != true,
              (1...4).contains(selected) else { return }
        session.ipv4SelectedOctet = selected
        session.ipv4VisualSubmitted = false
    }

    private var visualFontScale: Double {
        switch dynamicTypeSize {
        case .xSmall: return 0.9
        case .small: return 0.95
        case .medium, .large: return 1.0
        case .xLarge: return 1.1
        case .xxLarge: return 1.2
        case .xxxLarge: return 1.3
        case .accessibility1: return 1.45
        case .accessibility2: return 1.65
        case .accessibility3: return 1.85
        case .accessibility4: return 2.0
        case .accessibility5: return 2.2
        @unknown default: return 1.0
        }
    }

    private func checkIPv4Boundary() {
        guard let example = lesson.ipv4Visual?.examples.last,
              let selected = session.ipv4SelectedOctet,
              session.ipv4VisualSubmitted != true,
              let address = IPv4AddressValue(ip: example.ip, prefix: example.prefix) else { return }
        session.ipv4VisualSubmitted = true
        session.ipv4VisualSolved = address.isCorrectBoundary(selected)
        if session.ipv4VisualSolved != true { session.mistakes += 1 }
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

    private var explanationScrollTarget: String? {
        guard lesson.topology != nil, let kind = plan.step(at: session.stepIndex)?.kind,
              kind == .diagram || kind == .text else { return nil }
        return "topology-anchor"
    }

    private var feedbackScrollTarget: String? {
        if plan.step(at: session.stepIndex)?.kind == .diagram,
           lesson.subnetMaskIntroduction != nil, session.subnetMaskProgress?.stage == 3,
           session.subnetMaskProgress?.boundarySubmitted == true { return "mask-feedback" }
        if plan.step(at: session.stepIndex)?.kind == .diagram,
           lesson.ipv4Visual != nil, session.ipv4VisualSubmitted == true {
            return "ipv4-feedback"
        }
        guard plan.step(at: session.stepIndex)?.kind == .question else { return nil }
        let submitted = session.stepIndex == plan.challengeIndex ? session.challengeSubmitted : session.answerSubmitted
        return submitted ? "answer-feedback" : nil
    }

    private var scrollRequest: String {
        if lesson.ipv4Foundation != nil, plan.step(at: session.stepIndex)?.kind == .diagram {
            return "foundation-\(session.ipv4FoundationProgress?.stage ?? 0)"
        }
        if lesson.subnetMaskIntroduction != nil, plan.step(at: session.stepIndex)?.kind == .diagram {
            let progress = session.subnetMaskProgress ?? SubnetMaskProgress()
            return "mask-\(progress.stage)-\(progress.boundarySubmitted)"
        }
        if lesson.ipv4Introduction != nil, plan.step(at: session.stepIndex)?.kind == .diagram {
            return "introduction-\(session.ipv4IntroductionProgress?.stage ?? 0)"
        }
        if explanationScrollTarget != nil { return "topology-explanation" }
        if let feedbackScrollTarget { return "\(session.stepIndex)-\(feedbackScrollTarget)" }
        return conversationScrollTarget ?? "step-\(session.stepIndex)"
    }

    private func topologyEmphasis(in paragraph: String) -> String? {
        guard let topology = lesson.topology else { return nil }
        let labels = topology.nodes.map(\.label).filter { paragraph.contains($0) }
        return labels.isEmpty ? nil : labels.joined(separator: " · ")
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
            if lesson.ipv4Foundation != nil {
                let progress = session.ipv4FoundationProgress ?? IPv4FoundationProgress()
                if progress.stage >= (lesson.ipv4Foundation?.stageCount ?? 4) - 1 { return "完成本课" }
                return "下一步"
            }
            if lesson.subnetMaskIntroduction != nil {
                let progress = session.subnetMaskProgress ?? SubnetMaskProgress()
                switch progress.stage {
                case 0: return "看看掩码怎么标记"
                case 1: return "只换掩码看看"
                case 2: return "自己选一次分界"
                default: return progress.boundarySolved ? "找找对应关系" : "检查分界"
                }
            }
            if lesson.ipv4Introduction != nil {
                switch session.ipv4IntroductionProgress?.stage ?? 0 {
                case 0: return "拆开这一段"
                case 1: return "看看取值范围"
                case 2: return "拼回完整地址"
                default: return "找找对应关系"
                }
            }
            if lesson.ipv4Visual != nil {
                if (session.ipv4VisualPhase ?? 0) == 0 { return "换一条试试" }
                return session.ipv4VisualSolved == true ? "继续看一小步" : "检查分界"
            }
            return lesson.explanation.isEmpty ? "找找对应关系" : "继续看一小步"
        case .text:
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
            if lesson.ipv4Foundation != nil {
                return session.ipv4FoundationProgress?.canAdvance ?? true
            }
            if lesson.subnetMaskIntroduction != nil {
                let progress = session.subnetMaskProgress ?? SubnetMaskProgress()
                return progress.canAdvance || progress.stage == 3 &&
                    progress.selectedBoundary != nil && !progress.boundarySubmitted
            }
            if lesson.ipv4Introduction != nil {
                return session.ipv4IntroductionProgress?.canAdvance == true
            }
            guard lesson.ipv4Visual != nil, (session.ipv4VisualPhase ?? 0) == 1 else { return true }
            return session.ipv4VisualSolved == true ||
                (session.ipv4SelectedOctet != nil && session.ipv4VisualSubmitted != true)
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
                        earnedXP = store.finish(session.stageSession(lesson: lesson))
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
                        if lesson.ipv4Visual != nil {
                            session.ipv4VisualPhase = 0
                            session.ipv4VisualFinished = false
                        }
                    }
                    else { plan.submitAnswer(session.selectedAnswer ?? "", in: &session) }
                }
            }
        case .diagram:
            if let foundation = lesson.ipv4Foundation {
                var progress = session.ipv4FoundationProgress ?? IPv4FoundationProgress()
                let isLastStage = progress.stage >= foundation.stageCount - 1
                progress.advance(stageCount: foundation.stageCount)
                session.ipv4FoundationProgress = progress
                if isLastStage {
                    plan.advance(&session)
                    if plan.isComplete(session) { earnedXP = store.finish(session.stageSession(lesson: lesson)) }
                }
                return
            }
            if let configuration = lesson.subnetMaskIntroduction {
                var progress = session.subnetMaskProgress ?? SubnetMaskProgress()
                if progress.stage == 3 && !progress.boundarySolved {
                    if progress.submitBoundary(configuration: configuration) == false { session.mistakes += 1 }
                } else {
                    let lastStage = progress.stage == 3
                    progress.advance()
                    session.subnetMaskProgress = progress
                    if lastStage { plan.advance(&session) }
                    return
                }
                session.subnetMaskProgress = progress
                return
            }
            if lesson.ipv4Introduction != nil {
                var progress = session.ipv4IntroductionProgress ?? IPv4IntroductionProgress()
                let isLastStage = progress.stage == 3
                progress.advance()
                session.ipv4IntroductionProgress = progress
                if isLastStage { plan.advance(&session) }
                return
            }
            if lesson.ipv4Visual != nil {
                if (session.ipv4VisualPhase ?? 0) == 0 {
                    session.ipv4VisualPhase = 1
                    return
                }
                if session.ipv4VisualSolved != true {
                    checkIPv4Boundary()
                    return
                }
            }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                if lesson.ipv4Visual != nil { session.ipv4VisualFinished = true }
                plan.advance(&session)
            }
        case .text:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { plan.advance(&session) }
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
