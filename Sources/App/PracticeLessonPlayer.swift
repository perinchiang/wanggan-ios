import SwiftUI

private struct PracticeFeedbackHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PracticeActionHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct PracticeLessonPlayer: View {
    let lesson: Lesson
    let practice: PracticeLesson
    let usesStaticPresentation: Bool
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var session: LessonSession
    @State private var earnedXP = 0
    @State private var showExit = false
    @State private var discardingSession = false
    @State private var feedbackTick = 0
    @State private var feedbackHeight: CGFloat = 0
    @State private var actionHeight: CGFloat = 0
    @Namespace private var wordMotion

    init(lesson: Lesson, practice: PracticeLesson, initialSession: LessonSession, usesStaticPresentation: Bool) {
        self.lesson = lesson
        self.practice = practice
        self.usesStaticPresentation = usesStaticPresentation
        var initial = initialSession
        if initial.practice == nil { initial.practice = PracticeSession(lesson: practice) }
        _session = State(initialValue: initial)
    }

    private var progress: PracticeSession { session.practice! }
    private var question: PracticeQuestion? { practice.question(progress.currentID) }
    private var reduceMotion: Bool { systemReduceMotion || usesStaticPresentation }
    private var valid: Bool { progress.isValid(for: practice) }

    var body: some View {
        GeometryReader { viewport in
            lessonContent
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    footer
                }
                .overlay(alignment: .bottom) {
                    feedbackPanel(maxFeedbackHeight: viewport.size.height * 0.4)
                        .offset(y: -actionHeight)
                }
        }
        .background(Theme.paper).foregroundStyle(Theme.ink)
        .onPreferenceChange(PracticeFeedbackHeight.self) { feedbackHeight = $0 }
        .onPreferenceChange(PracticeActionHeight.self) { actionHeight = $0 }
        .transaction { transaction in
            if reduceMotion { transaction.disablesAnimations = true }
        }
        .sensoryFeedback(.selection, trigger: feedbackTick) { _, _ in store.hapticsEnabled }
        .onAppear {
            guard valid else { return }
            if progress.isComplete { earnedXP = store.finish(session) }
            else { store.saveDraft(session) }
        }
        .onChange(of: session) { _, new in
            if !discardingSession && valid && !progress.isComplete { store.saveDraft(new) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && !discardingSession && valid && !progress.isComplete { store.saveDraft(session) }
        }
        .alert("确认退出？", isPresented: $showExit) {
            Button("取消", role: .cancel) { }
            Button("确定退出", role: .destructive) {
                discardingSession = true
                store.discardDraft(session)
                dismiss()
            }
        } message: { Text("退出后，这次未完成的小节将从头开始。") }
    }

    private var lessonContent: some View {
        VStack(spacing: 0) {
            if !progress.isComplete { header }
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            Color.clear.frame(height: 0).id("question-top")
                            if !valid {
                                EmptyLearningState(title: "这节课的内容已更新", detail: "上次做到一半的题目已保留。点左上角退出并确认后，可以开始新版；已完成记录和 XP 会保留。")
                            } else if progress.isComplete {
                                CompletionView(lesson: lesson, earnedXP: earnedXP,
                                               totalXP: store.ledger.totalXP, level: store.ledger.level)
                            } else if let question {
                                questionContent(question)
                                Spacer(minLength: 20)
                                answerContent(question)
                            }
                        }
                        .padding(.horizontal, 22).padding(.bottom, 22)
                        .frame(minHeight: geometry.size.height, alignment: .top)
                        // Extend the scroll range without resizing the question or moving its answers.
                        Color.clear.frame(height: progress.attempt.result == nil ? 0 : feedbackHeight)
                    }
                    .onChange(of: progress.currentID) { _, _ in proxy.scrollTo("question-top", anchor: .top) }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button { showExit = true } label: {
                Image(systemName: "xmark").font(.system(size: 20)).frame(width: 44, height: 44)
            }.accessibilityLabel("退出小节").accessibilityIdentifier("exit-lesson")
            ThinProgress(value: Double(progress.completedIDs.count) / Double(practice.questions.count))
            Text("\(progress.completedIDs.count) / \(practice.questions.count)")
                .font(.caption.monospacedDigit()).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityIdentifier("practice-progress")
        }.padding(.horizontal, 14).padding(.vertical, 10)
    }

    @ViewBuilder private func questionContent(_ question: PracticeQuestion) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(lesson.title).font(.subheadline).foregroundStyle(Theme.muted)
            Text(question.kind == .fillBlank ? "选词填空" : question.prompt)
                .font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("practice-prompt")
            ForEach(question.figures) { ConnectionFigureView(figure: $0) }
            if question.kind == .fillBlank { blankSentence(question) }
        }
    }

    private func blankSentence(_ question: PracticeQuestion) -> some View {
        let parts = question.prompt.components(separatedBy: "____")
        let selected = question.options.first { $0.id == progress.attempt.selectedID }
        return VStack(alignment: .leading, spacing: 8) {
            Text(parts[0]).font(.title3)
            HStack(spacing: 8) {
                Button {
                    if let selected { select(selected.id, question: question) }
                } label: {
                    Group {
                        if let selected {
                            Text(selected.text).matchedGeometryEffect(id: selected.id, in: wordMotion, properties: .position)
                        } else { Text("____").foregroundStyle(Theme.muted) }
                    }
                    .font(.title3.weight(.semibold)).padding(.horizontal, 18).padding(.vertical, 12)
                    .background(selected == nil ? Theme.line.opacity(0.3) : Theme.lime, in: .rect(cornerRadius: 12))
                }.buttonStyle(.plain).disabled(selected == nil || progress.attempt.result != nil)
                    .accessibilityLabel(selected.map { "已填入\($0.text)，点按撤回" } ?? "空位")
                    .accessibilityIdentifier("practice-blank")
                Text(parts[1]).font(.title3)
            }
        }
    }

    @ViewBuilder private func answerContent(_ question: PracticeQuestion) -> some View {
        if let matching = question.matching {
            MatchingView(exercise: progress.attempt.result == nil ? matching : answerOrdered(matching),
                         matches: progress.attempt.result == false ? matching.solution : progress.attempt.matches,
                         onPair: { left, right in
                             var correct = false
                             update { correct = $0.attempt.pair(left, right, question: question) }
                             return correct
                         }, usesStaticPresentation: usesStaticPresentation,
                         isLocked: progress.attempt.result != nil, compact: true,
                         statusOverride: progress.attempt.result == false ? "看看正确对应" : nil)
                .id(question.id)
        } else {
            VStack(spacing: 12) {
                ForEach(question.options) { option in
                    optionButton(option, question: question)
                }
            }
        }
    }

    private func answerOrdered(_ exercise: MatchingExercise) -> MatchingExercise {
        MatchingExercise(prompt: exercise.prompt, left: exercise.left,
                         right: exercise.left.compactMap { left in
                             exercise.right.first { $0.id == exercise.solution[left.id] }
                         }, solution: exercise.solution, explanation: exercise.explanation)
    }

    private func optionButton(_ option: AnswerOption, question: PracticeQuestion) -> some View {
        let selected = progress.attempt.selectedID == option.id
        let submitted = progress.attempt.result != nil
        let correct = submitted && option.id == question.correctID
        let wrong = submitted && selected && !correct
        return Button { select(option.id, question: question) } label: {
            HStack {
                Spacer(minLength: 0)
                if question.kind == .fillBlank && selected {
                    Text("已填入").foregroundStyle(Theme.muted)
                } else {
                    Text(option.text)
                        .matchedGeometryEffect(id: option.id, in: wordMotion, properties: .position)
                }
                if correct { Image(systemName: "checkmark.circle.fill") }
                if wrong { Image(systemName: "xmark.circle.fill") }
                Spacer(minLength: 0)
            }
            .font(.body.weight(.semibold)).padding(.horizontal, 14).padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(wrong ? Color.red : Theme.ink)
            .background(correct ? Theme.lime : wrong ? Color.red.opacity(0.08) : Theme.surface,
                        in: .rect(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(wrong ? .red : correct ? Theme.ink : Theme.line, lineWidth: 2))
        }.buttonStyle(PressStyle()).disabled(submitted)
            .accessibilityLabel(option.text)
            .accessibilityValue(correct ? "正确答案" : wrong ? "选择错误" : selected ? "已选中" : "未选中")
            .accessibilityIdentifier("practice-option-\(option.id)")
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !valid {
                PrimaryButton(title: "返回学习路线", symbol: "") { dismiss() }
            } else if progress.isComplete {
                PrimaryButton(title: "回到学习路线", identifier: "continue-learning") { dismiss() }
            } else {
                PrimaryButton(title: progress.attempt.result == nil && question?.kind == .fillBlank ? "检查" : "继续",
                              enabled: progress.attempt.result != nil || (question?.kind == .fillBlank && progress.attempt.selectedID != nil),
                              symbol: "", identifier: "primary-action") { performAction() }
            }
        }
        .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(feedbackTint)
        .background(Theme.paper)
        .overlay(alignment: .top) {
            if progress.attempt.result == nil { Rectangle().fill(Theme.line).frame(height: 1) }
        }
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: PracticeActionHeight.self, value: geometry.size.height)
            }
        }
    }

    @ViewBuilder private func feedbackPanel(maxFeedbackHeight: CGFloat) -> some View {
        if valid, let question, let result = progress.attempt.result {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    ScrollView { feedbackContent(question, result: result) }
                        .frame(height: maxFeedbackHeight)
                } else {
                    feedbackContent(question, result: result)
                }
            }
            .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(feedbackTint).background(Theme.paper)
            .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(key: PracticeFeedbackHeight.self, value: geometry.size.height)
                }
            }
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: result)
        }
    }

    private var feedbackTint: Color {
        progress.attempt.result == nil ? Theme.paper : progress.attempt.result == true ? Theme.lime.opacity(0.22) : Theme.line.opacity(0.35)
    }

    private func feedbackContent(_ question: PracticeQuestion, result: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(result ? "答对了" : question.role == .exploration ? "看看答案" : "这题答错了",
                  systemImage: result ? "checkmark.circle.fill" : question.role == .exploration ? "lightbulb" : "xmark.circle.fill")
                .font(.title3.bold()).foregroundStyle(result ? Theme.ink : question.role == .exploration ? Theme.ink : .red)
                .accessibilityIdentifier("practice-result")
            if !result {
                Text("正确答案：\(question.answerText)").font(.headline).fixedSize(horizontal: false, vertical: true)
            }
            Text(question.explanation).font(.body).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }

    private func select(_ id: String, question: PracticeQuestion) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) {
            update { $0.attempt.select(id, question: question) }
        }
    }
    private func update(_ action: (inout PracticeSession) -> Void) {
        guard valid else { return }
        var saved = progress
        action(&saved)
        session.practice = saved
        session.mistakes = saved.mistakes
        feedbackTick += 1
    }
    private func performAction() {
        guard let question else { return }
        if progress.attempt.result == nil {
            update { $0.attempt.submit(question) }
        } else {
            update { $0.advance(lesson: practice) }
            if progress.isComplete {
                session.stage = .complete
                earnedXP = store.finish(session)
            }
        }
    }
}
