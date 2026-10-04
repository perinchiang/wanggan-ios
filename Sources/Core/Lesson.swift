import Foundation

struct AnswerOption: Codable, Equatable, Identifiable {
    let id: String
    let text: String
    let feedback: String
}

struct SceneMessage: Codable, Equatable, Identifiable {
    let id: String
    let text: String
    let visual: String?
}

struct SceneDevice: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let address: String
    let prefix: String
}

struct Question: Codable, Equatable {
    let prompt: String
    let scene: [SceneMessage]
    let devices: [SceneDevice]?
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

struct Chapter: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let orderedLessonIDs: [String]
}

struct Course: Codable, Equatable, Identifiable {
    let id: String
    let revision: Int
    let title: String
    let chapters: [Chapter]
}

struct LessonCatalog: Codable {
    let course: Course
    let lessons: [Lesson]

    var orderedLessonIDs: [String] { course.chapters.flatMap(\.orderedLessonIDs) }

    func lessons(in chapterID: String) -> [Lesson] {
        guard let chapter = course.chapters.first(where: { $0.id == chapterID }) else { return [] }
        return chapter.orderedLessonIDs.compactMap { id in lessons.first { $0.id == id } }
    }

    func validate() throws {
        guard !lessons.isEmpty, Set(lessons.map(\.id)).count == lessons.count else {
            throw ContentError.invalid("课程为空或标识重复")
        }
        guard course.revision >= 1,
              !course.chapters.isEmpty,
              Set(course.chapters.map(\.id)).count == course.chapters.count,
              !course.chapters.contains(where: { $0.orderedLessonIDs.isEmpty }) else {
            throw ContentError.invalid("课程目录为空或章节标识重复")
        }
        let chapterIDs = course.chapters.flatMap(\.orderedLessonIDs)
        guard chapterIDs.count == lessons.count, Set(chapterIDs) == Set(lessons.map(\.id)) else {
            throw ContentError.invalid("章节没有恰好覆盖每一课")
        }
        for lesson in lessons {
            for question in [lesson.question, lesson.challenge] {
                guard question.options.count >= 2,
                      Set(question.options.map(\.id)).count == question.options.count,
                      question.options.contains(where: { $0.id == question.correctID }),
                      !question.prompt.isEmpty,
                      !question.scene.isEmpty,
                      Set(question.scene.map(\.id)).count == question.scene.count,
                      question.scene.allSatisfy({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                      question.scene.allSatisfy({ message in message.visual.map { ["network", "devices"].contains($0) } ?? true }) else {
                    throw ContentError.invalid("\(lesson.id) 的选项不完整")
                }
                if let devices = question.devices {
                    guard !devices.isEmpty, Set(devices.map(\.id)).count == devices.count,
                          devices.allSatisfy({ !$0.name.isEmpty && !$0.address.isEmpty && !$0.prefix.isEmpty }) else {
                        throw ContentError.invalid("\(lesson.id) 的地址信息不完整")
                    }
                }
                if question.scene.contains(where: { $0.visual == "devices" }), question.devices == nil {
                    throw ContentError.invalid("\(lesson.id) 缺少用于比较的地址")
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
