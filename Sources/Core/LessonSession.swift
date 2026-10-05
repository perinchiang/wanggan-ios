import Foundation

enum LessonStage: Int, Codable, CaseIterable {
    case question, explanation, matching, challenge, complete
}

struct LessonSession: Codable, Equatable, Identifiable {
    let id: UUID
    let lessonID: String
    var stage: LessonStage = .question
    var selectedAnswer: String?
    // Optional fields preserve decoding of drafts saved before conversation scenes existed.
    var questionSceneStep: Int?
    var challengeSceneStep: Int?
    var answerSubmitted = false
    var explanationIndex = 0
    var matches: [String: String] = [:]
    var matchingSubmitted = false
    var matchingSolved = false
    var challengeAnswer: String?
    var challengeSubmitted = false
    var challengeSolved = false
    var mistakes = 0
    var earnedXP: Int?
    // Optional to keep drafts from earlier app versions decodable.
    var ipv4VisualPhase: Int?
    var ipv4SelectedOctet: Int?
    var ipv4VisualSubmitted: Bool?
    var ipv4VisualSolved: Bool?
    var ipv4VisualFinished: Bool?

    init(lessonID: String, id: UUID = UUID()) {
        self.id = id
        self.lessonID = lessonID
    }

    func sceneStep(for question: Question, challenge: Bool) -> Int {
        // Existing drafts with an answer should resume at the answer, not replay the setup.
        let hasAnswer = challenge ? challengeAnswer != nil || challengeSubmitted : selectedAnswer != nil || answerSubmitted
        if hasAnswer { return question.scene.count }
        let saved = challenge ? challengeSceneStep : questionSceneStep
        return min(max(saved ?? 0, 0), question.scene.count)
    }

    func sceneIsComplete(for question: Question, challenge: Bool) -> Bool {
        sceneStep(for: question, challenge: challenge) == question.scene.count
    }

    mutating func revealNextScene(for question: Question, challenge: Bool) {
        let next = min(sceneStep(for: question, challenge: challenge) + 1, question.scene.count)
        if challenge { challengeSceneStep = next }
        else { questionSceneStep = next }
    }

    mutating func submitQuestion(_ question: Question) {
        guard !answerSubmitted, let selectedAnswer,
              question.options.contains(where: { $0.id == selectedAnswer }) else { return }
        answerSubmitted = true
        if selectedAnswer != question.correctID { mistakes += 1 }
    }

    mutating func connect(_ left: String, to right: String) {
        guard !matchingSolved else { return }
        // A right-hand item can only have one incoming connection.
        matches = matches.filter { $0.key == left || $0.value != right }
        matches[left] = right
        matchingSubmitted = false
    }

    mutating func submitMatching(_ exercise: MatchingExercise) {
        guard !matchingSubmitted, matches.count == exercise.left.count else { return }
        matchingSubmitted = true
        matchingSolved = exercise.isCorrect(matches)
        if !matchingSolved { mistakes += 1 }
    }

    mutating func submitChallenge(_ question: Question) {
        guard !challengeSubmitted, let challengeAnswer,
              question.options.contains(where: { $0.id == challengeAnswer }) else { return }
        challengeSubmitted = true
        challengeSolved = challengeAnswer == question.correctID
        if !challengeSolved { mistakes += 1 }
    }

    mutating func retryChallenge(question: Question) {
        guard !challengeSolved else { return }
        challengeSceneStep = sceneStep(for: question, challenge: true)
        challengeSubmitted = false
        challengeAnswer = nil
    }

    mutating func advance(lesson: Lesson) {
        switch stage {
        case .question:
            if answerSubmitted { stage = .explanation }
        case .explanation:
            if explanationIndex + 1 < lesson.explanation.count { explanationIndex += 1 }
            else { stage = .matching }
        case .matching:
            if matchingSolved { stage = .challenge }
        case .challenge:
            if challengeSolved { stage = .complete }
        case .complete: break
        }
    }
}
