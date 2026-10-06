import Foundation

enum StepKind: String, Codable {
    case conversation
    case question
    case diagram
    case text
    case matching
    case summary
}

enum StepPayload: Codable, Equatable {
    case conversation(SceneMessage)
    case question(Question)
    case diagram(String)
    case text(String)
    case matching(MatchingExercise)
    case summary(String)

    var kind: StepKind {
        switch self {
        case .conversation: return .conversation
        case .question: return .question
        case .diagram: return .diagram
        case .text: return .text
        case .matching: return .matching
        case .summary: return .summary
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind, conversation, question, diagram, text, matching, summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(StepKind.self, forKey: .kind) {
        case .conversation:
            self = .conversation(try container.decode(SceneMessage.self, forKey: .conversation))
        case .question:
            self = .question(try container.decode(Question.self, forKey: .question))
        case .diagram:
            self = .diagram(try container.decode(String.self, forKey: .diagram))
        case .text:
            self = .text(try container.decode(String.self, forKey: .text))
        case .matching:
            self = .matching(try container.decode(MatchingExercise.self, forKey: .matching))
        case .summary:
            self = .summary(try container.decode(String.self, forKey: .summary))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .conversation(let value):
            try container.encode(StepKind.conversation, forKey: .kind)
            try container.encode(value, forKey: .conversation)
        case .question(let value):
            try container.encode(StepKind.question, forKey: .kind)
            try container.encode(value, forKey: .question)
        case .diagram(let value):
            try container.encode(StepKind.diagram, forKey: .kind)
            try container.encode(value, forKey: .diagram)
        case .text(let value):
            try container.encode(StepKind.text, forKey: .kind)
            try container.encode(value, forKey: .text)
        case .matching(let value):
            try container.encode(StepKind.matching, forKey: .kind)
            try container.encode(value, forKey: .matching)
        case .summary(let value):
            try container.encode(StepKind.summary, forKey: .kind)
            try container.encode(value, forKey: .summary)
        }
    }
}

struct LessonStep: Codable, Equatable, Identifiable {
    let id: String
    let payload: StepPayload

    var kind: StepKind { payload.kind }
}

extension Lesson {
    var steps: [LessonStep] {
        if ipv4Foundation != nil {
            return [
                LessonStep(id: "\(id).diagram", payload: .diagram(diagram)),
                LessonStep(id: "\(id).summary", payload: .summary(takeaway))
            ]
        }
        var result: [LessonStep] = []
        for message in question.scene {
            result.append(LessonStep(id: "\(id).question.scene.\(message.id)", payload: .conversation(message)))
        }
        result.append(LessonStep(id: "\(id).question", payload: .question(question)))
        result.append(LessonStep(id: "\(id).diagram", payload: .diagram(diagram)))
        for (index, paragraph) in explanation.enumerated() {
            result.append(LessonStep(id: "\(id).explanation.\(index)", payload: .text(paragraph)))
        }
        if usesMatching {
            result.append(LessonStep(id: "\(id).matching", payload: .matching(matching)))
        }
        for message in challenge.scene {
            result.append(LessonStep(id: "\(id).challenge.scene.\(message.id)", payload: .conversation(message)))
        }
        result.append(LessonStep(id: "\(id).challenge", payload: .question(challenge)))
        for page in challenge.answerExplanation ?? [] {
            result.append(LessonStep(id: "\(id).challenge.explanation.\(page.id)", payload: .text(page.text)))
        }
        result.append(LessonStep(id: "\(id).summary", payload: .summary(takeaway)))
        return result
    }
}

struct StepSession: Codable, Equatable {
    let id: UUID
    let lessonID: String
    var stepIndex = 0
    var selectedAnswer: String?
    var answerSubmitted = false
    var matches: [String: String] = [:]
    var matchingSubmitted = false
    var matchingSolved = false
    var challengeAnswer: String?
    var challengeSubmitted = false
    var challengeSolved = false
    var challengeExplanationID: String?
    var mistakes = 0
    var ipv4VisualPhase: Int?
    var ipv4SelectedOctet: Int?
    var ipv4VisualSubmitted: Bool?
    var ipv4VisualSolved: Bool?
    var ipv4VisualFinished: Bool?
    var ipv4FoundationProgress: IPv4FoundationProgress?
    var ipv4IntroductionProgress: IPv4IntroductionProgress?
    var subnetMaskProgress: SubnetMaskProgress?

    init(lessonID: String, id: UUID = UUID()) {
        self.id = id
        self.lessonID = lessonID
    }
}

struct LessonPlan {
    let lesson: Lesson
    let steps: [LessonStep]
    let questionSceneCount: Int
    let questionIndex: Int
    let matchingIndex: Int
    let challengeSceneCount: Int
    let challengeIndex: Int
    let summaryIndex: Int

    init(lesson: Lesson) {
        let steps = lesson.steps
        self.lesson = lesson
        self.steps = steps
        questionSceneCount = lesson.question.scene.count
        questionIndex = steps.firstIndex { $0.id == "\(lesson.id).question" } ?? steps.count
        if let index = steps.firstIndex(where: { $0.id == "\(lesson.id).matching" }) {
            matchingIndex = index
        } else if let firstChallengeScene = steps.firstIndex(where: { $0.id.hasPrefix("\(lesson.id).challenge.scene.") }) {
            // Preserve the old boundary arithmetic even when matching is skipped.
            matchingIndex = firstChallengeScene - 1
        } else {
            matchingIndex = steps.count
        }
        challengeSceneCount = lesson.challenge.scene.count
        challengeIndex = steps.firstIndex { $0.id == "\(lesson.id).challenge" } ?? steps.count
        summaryIndex = steps.firstIndex { $0.id == "\(lesson.id).summary" }!
    }

    func step(at index: Int) -> LessonStep? {
        guard steps.indices.contains(index) else { return nil }
        return steps[index]
    }

    func question(at index: Int) -> Question? {
        guard let step = step(at: index) else { return nil }
        if case .question(let question) = step.payload { return question }
        return nil
    }

    func matching(at index: Int) -> MatchingExercise? {
        guard let step = step(at: index) else { return nil }
        if case .matching(let exercise) = step.payload { return exercise }
        return nil
    }

    func isComplete(_ session: StepSession) -> Bool {
        if lesson.ipv4Foundation != nil {
            return session.ipv4FoundationProgress?.finished == true && session.stepIndex == summaryIndex
        }
        return session.challengeSolved && session.stepIndex >= summaryIndex
    }

    func answerExplanation(at index: Int) -> AnswerExplanation? {
        guard index > challengeIndex, index < summaryIndex else { return nil }
        let pageIndex = index - challengeIndex - 1
        guard let pages = lesson.challenge.answerExplanation, pages.indices.contains(pageIndex) else { return nil }
        return pages[pageIndex]
    }

    func canAdvance(_ session: StepSession) -> Bool {
        guard let step = step(at: session.stepIndex) else { return false }
        switch step.kind {
        case .diagram:
            if lesson.ipv4Foundation != nil { return session.ipv4FoundationProgress?.finished == true }
            if lesson.subnetMaskIntroduction != nil { return session.subnetMaskProgress?.finished == true }
            return lesson.ipv4Introduction == nil || session.ipv4IntroductionProgress?.finished == true
        case .text:
            return session.stepIndex <= challengeIndex || session.challengeSolved
        case .conversation, .summary:
            return true
        case .question:
            if session.stepIndex == questionIndex { return session.answerSubmitted }
            return session.challengeSolved
        case .matching:
            return session.matchingSolved
        }
    }

    func advance(_ session: inout StepSession) {
        guard canAdvance(session), session.stepIndex < summaryIndex else { return }
        session.stepIndex += 1
        session.challengeExplanationID = answerExplanation(at: session.stepIndex)?.id
    }

    func submitAnswer(_ optionID: String, in session: inout StepSession) {
        guard session.stepIndex == questionIndex, let question = question(at: questionIndex),
              !session.answerSubmitted,
              question.options.contains(where: { $0.id == optionID }) else { return }
        session.selectedAnswer = optionID
        session.answerSubmitted = true
        if optionID != question.correctID { session.mistakes += 1 }
    }

    func connect(_ left: String, to right: String, in session: inout StepSession) {
        guard let exercise = matching(at: matchingIndex), !session.matchingSolved else { return }
        session.matches = session.matches.filter { $0.key == left || $0.value != right }
        session.matches[left] = right
        session.matchingSubmitted = false
    }

    // A mismatch is transient feedback, never a saved answer or a penalty.
    @discardableResult
    func matchPair(_ left: String, to right: String, in session: inout StepSession) -> Bool {
        guard session.stepIndex == matchingIndex,
              let exercise = matching(at: matchingIndex), !session.matchingSolved,
              exercise.left.contains(where: { $0.id == left }),
              exercise.right.contains(where: { $0.id == right }) else { return false }
        session.matches = session.matches.filter { exercise.solution[$0.key] == $0.value }
        guard session.matches[left] == nil, !session.matches.values.contains(right),
              exercise.solution[left] == right else { return false }
        session.matches[left] = right
        session.matchingSolved = exercise.isCorrect(session.matches)
        session.matchingSubmitted = session.matchingSolved
        return true
    }

    func submitMatching(in session: inout StepSession) {
        guard let exercise = matching(at: matchingIndex), !session.matchingSubmitted,
              session.matches.count == exercise.left.count else { return }
        session.matchingSubmitted = true
        session.matchingSolved = exercise.isCorrect(session.matches)
        if !session.matchingSolved { session.mistakes += 1 }
    }

    func submitChallenge(_ optionID: String, in session: inout StepSession) {
        guard session.stepIndex == challengeIndex, let question = question(at: challengeIndex),
              !session.challengeSubmitted,
              question.options.contains(where: { $0.id == optionID }) else { return }
        session.challengeAnswer = optionID
        session.challengeSubmitted = true
        session.challengeSolved = optionID == question.correctID
        if !session.challengeSolved { session.mistakes += 1 }
    }

    func retryChallenge(in session: inout StepSession) {
        guard !session.challengeSolved else { return }
        session.challengeSubmitted = false
        session.challengeAnswer = nil
    }
}

extension StepSession {
    init(lesson: Lesson, from stage: LessonSession) {
        let plan = LessonPlan(lesson: lesson)
        self.init(lessonID: lesson.id, id: stage.id)
        mistakes = stage.mistakes
        ipv4VisualPhase = stage.ipv4VisualPhase
        ipv4SelectedOctet = stage.ipv4SelectedOctet
        ipv4VisualSubmitted = stage.ipv4VisualSubmitted
        ipv4VisualSolved = stage.ipv4VisualSolved
        ipv4VisualFinished = stage.ipv4VisualFinished
        ipv4FoundationProgress = stage.ipv4FoundationProgress
        ipv4IntroductionProgress = stage.ipv4IntroductionProgress
        subnetMaskProgress = stage.subnetMaskProgress
        selectedAnswer = stage.selectedAnswer
        answerSubmitted = stage.answerSubmitted
        matches = stage.matches
        matchingSubmitted = stage.matchingSubmitted
        matchingSolved = stage.matchingSolved
        challengeAnswer = stage.challengeAnswer
        challengeSubmitted = stage.challengeSubmitted
        challengeSolved = stage.challengeSolved
        if let answer = challengeAnswer, !lesson.challenge.options.contains(where: { $0.id == answer }) {
            // A removed choice must not leave an old draft submitted or blocked.
            challengeAnswer = nil
            challengeSubmitted = false
            challengeSolved = false
        }
        if lesson.ipv4Foundation != nil {
            // Older quiz drafts resume at the observed animation, with the same identity.
            stepIndex = ipv4FoundationProgress?.finished == true ? plan.summaryIndex : 0
            return
        }
        if stage.stage == .matching, lesson.usesMatching {
            matches = matches.filter { lesson.matching.solution[$0.key] == $0.value }
            matchingSolved = lesson.matching.isCorrect(matches)
            matchingSubmitted = matchingSolved
        }
        switch stage.stage {
        case .question:
            stepIndex = min(stage.sceneStep(for: lesson.question, challenge: false), plan.questionSceneCount)
        case .explanation:
            if lesson.ipv4Foundation != nil || lesson.ipv4Introduction != nil || lesson.subnetMaskIntroduction != nil {
                stepIndex = plan.questionIndex + 1
            } else if lesson.ipv4Visual != nil, stage.ipv4VisualPhase != nil, stage.ipv4VisualFinished != true {
                stepIndex = plan.questionIndex + 1
            } else {
                stepIndex = plan.questionIndex + 2 + min(stage.explanationIndex, max(lesson.explanation.count - 1, 0))
            }
        case .matching:
            stepIndex = lesson.usesMatching ? plan.matchingIndex : min(plan.matchingIndex + 1, plan.challengeIndex)
        case .challenge:
            stepIndex = min(plan.matchingIndex + 1 + stage.sceneStep(for: lesson.challenge, challenge: true), plan.challengeIndex)
            if challengeSolved, let savedID = stage.challengeExplanationID,
               let pageIndex = lesson.challenge.answerExplanation?.firstIndex(where: { $0.id == savedID }) {
                stepIndex = plan.challengeIndex + 1 + pageIndex
                challengeExplanationID = savedID
            }
        case .complete:
            stepIndex = plan.summaryIndex
        }
    }

    func stageSession(lesson: Lesson) -> LessonSession {
        let plan = LessonPlan(lesson: lesson)
        var result = LessonSession(lessonID: lesson.id, id: id)
        result.mistakes = mistakes
        result.ipv4VisualPhase = ipv4VisualPhase
        result.ipv4SelectedOctet = ipv4SelectedOctet
        result.ipv4VisualSubmitted = ipv4VisualSubmitted
        result.ipv4VisualSolved = ipv4VisualSolved
        result.ipv4VisualFinished = ipv4VisualFinished
        result.ipv4FoundationProgress = ipv4FoundationProgress
        result.ipv4IntroductionProgress = ipv4IntroductionProgress
        result.subnetMaskProgress = subnetMaskProgress
        result.selectedAnswer = selectedAnswer
        result.answerSubmitted = answerSubmitted
        result.matches = matches
        result.matchingSubmitted = lesson.usesMatching ? matchingSubmitted : true
        result.matchingSolved = lesson.usesMatching ? matchingSolved : true
        result.challengeAnswer = challengeAnswer
        result.challengeSubmitted = challengeSubmitted
        result.challengeSolved = challengeSolved
        result.challengeExplanationID = plan.answerExplanation(at: stepIndex)?.id
        if lesson.ipv4Foundation != nil {
            result.stage = plan.isComplete(self) ? .complete : .explanation
            result.observationCompleted = plan.isComplete(self)
            return result
        }
        if stepIndex < plan.questionIndex {
            result.stage = .question
            result.questionSceneStep = stepIndex
        } else if stepIndex == plan.questionIndex {
            result.stage = .question
            result.questionSceneStep = answerSubmitted ? lesson.question.scene.count : stepIndex
        } else if stepIndex < plan.matchingIndex || (!lesson.usesMatching && stepIndex == plan.matchingIndex) {
            result.stage = .explanation
            result.explanationIndex = max(min(stepIndex - plan.questionIndex - 2, lesson.explanation.count - 1), 0)
            if lesson.ipv4Visual != nil, stepIndex == plan.questionIndex + 1 {
                result.ipv4VisualPhase = ipv4VisualPhase ?? 0
                result.ipv4VisualFinished = false
            }
        } else if stepIndex == plan.matchingIndex {
            result.stage = .matching
        } else if stepIndex < plan.challengeIndex {
            result.stage = .challenge
            result.challengeSceneStep = min(stepIndex - plan.matchingIndex - 1, plan.challengeSceneCount)
        } else if stepIndex < plan.summaryIndex {
            result.stage = .challenge
            result.challengeSceneStep = lesson.challenge.scene.count
        } else {
            result.stage = .complete
            result.challengeSolved = true
        }
        return result
    }
}
