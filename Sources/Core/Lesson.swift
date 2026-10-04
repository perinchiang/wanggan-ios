import Foundation

struct AnswerOption: Codable, Equatable, Identifiable {
    let id: String
    let text: String
    let feedback: String
}

struct Question: Codable, Equatable {
    let prompt: String
    let context: String
    let options: [AnswerOption]
    let correctID: String
    let hint: String
}

struct MatchItem: Codable, Equatable, Identifiable {
    let id: String
    let text: String
    let symbol: String
}

struct MatchingExercise: Codable, Equatable {
    let prompt: String
    let left: [MatchItem]
    let right: [MatchItem]
    let solution: [String: String]
    let explanation: String

    func isCorrect(_ answers: [String: String]) -> Bool {
        answers == solution
    }
}

struct Lesson: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let takeaway: String
    let nextCuriosity: String
    let diagram: String
    let question: Question
    let explanation: [String]
    let matching: MatchingExercise
    let challenge: Question
    let sources: [String]
}

struct LessonCatalog: Codable {
    let chapter: String
    let lessons: [Lesson]

    func validate() throws {
        guard !lessons.isEmpty, Set(lessons.map(\.id)).count == lessons.count else {
            throw ContentError.invalid("课程为空或标识重复")
        }
        for lesson in lessons {
            for question in [lesson.question, lesson.challenge] {
                guard question.options.count >= 2,
                      Set(question.options.map(\.id)).count == question.options.count,
                      question.options.contains(where: { $0.id == question.correctID }),
                      !question.prompt.isEmpty else {
                    throw ContentError.invalid("\(lesson.id) 的选项不完整")
                }
            }
            let exercise = lesson.matching
            let left = Set(exercise.left.map(\.id))
            let right = Set(exercise.right.map(\.id))
            guard left.count == exercise.left.count, right.count == exercise.right.count,
                  !left.isEmpty, left.count == right.count,
                  Set(exercise.solution.keys) == left,
                  Set(exercise.solution.values) == right,
                  !lesson.explanation.isEmpty, !lesson.sources.isEmpty else {
                throw ContentError.invalid("\(lesson.id) 的连线或讲解不完整")
            }
        }
    }
}

enum ContentError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self { case .invalid(let message): return message }
    }
}
