import Foundation

enum LessonStage: Int, Codable, CaseIterable {
    case question, explanation, matching, challenge, complete
}

struct LessonSession: Codable, Equatable, Identifiable {
    let id: UUID
    let lessonID: String
    var stage: LessonStage = .question
    var selectedAnswer: String?
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

    init(lessonID: String) {
        self.id = UUID()
        self.lessonID = lessonID
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

    mutating func retryChallenge() {
        guard !challengeSolved else { return }
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
