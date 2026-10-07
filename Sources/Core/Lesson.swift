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
    /// Optional presentational role. nil keeps the narrator/tutor bubble.
    let speaker: String?
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
    /// Optional illustrated reading after a successful transfer answer.
    let answerExplanation: [AnswerExplanation]?
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
    let topology: TopologySpec?
    let ipv4Foundation: IPv4Foundation?
    let ipv4Visual: IPv4VisualLesson?
    let ipv4Introduction: IPv4Introduction?
    let subnetMaskIntroduction: SubnetMaskIntroduction?
    let question: Question
    let explanation: [String]
    /// Existing lessons show matching by default; a story may opt out when the
    /// interaction would interrupt rather than reinforce the learning thread.
    let matchingEnabled: Bool?
    let matching: MatchingExercise
    let challenge: Question
    let sources: [String]
    /// Short-question path. Old payloads remain for existing interrupted drafts.
    var practice: PracticeLesson? = nil

    var usesMatching: Bool { matchingEnabled ?? true }
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
    let archivedLessonIDs: [String]?
}

struct LessonCatalog: Codable {
    let course: Course
    let lessons: [Lesson]

    var orderedLessonIDs: [String] { course.chapters.flatMap(\.orderedLessonIDs) }
    var archivedLessonIDs: [String] { course.archivedLessonIDs ?? [] }
    // Archived pilots sort before the active route only for draft preservation.
    // They never participate in recommendation or unlocking.
    var allLessonIDs: [String] { archivedLessonIDs + orderedLessonIDs }

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
        let archivedIDs = course.archivedLessonIDs ?? []
        let listedIDs = chapterIDs + archivedIDs
        guard Set(chapterIDs).isDisjoint(with: Set(archivedIDs)),
              Set(archivedIDs).count == archivedIDs.count,
              listedIDs.count == lessons.count,
              Set(listedIDs) == Set(lessons.map(\.id)) else {
            throw ContentError.invalid("章节与归档列表没有恰好覆盖每一课")
        }
        for lesson in lessons {
            if let practice = lesson.practice, !practice.isValid {
                throw ContentError.invalid("\(lesson.id) 的短题内容不完整")
            }
            if let topology = lesson.topology {
                // The topology reveals one stage per explanation paragraph (stage 1
                // anchors the diagram step), so stages must fit the text budget and
                // stay exclusive from the other visual mechanisms.
                guard topology.isValid,
                      lesson.ipv4Foundation == nil, lesson.ipv4Visual == nil,
                      lesson.ipv4Introduction == nil, lesson.subnetMaskIntroduction == nil,
                      !lesson.explanation.isEmpty,
                      topology.maxStage <= lesson.explanation.count + 1 else {
                    throw ContentError.invalid("\(lesson.id) 的拓扑图参数无效")
                }
            }
            if let foundation = lesson.ipv4Foundation {
                guard foundation.isValid,
                      lesson.ipv4Introduction == nil,
                      lesson.subnetMaskIntroduction == nil,
                      lesson.ipv4Visual == nil,
                      lesson.topology == nil,
                      lesson.explanation.isEmpty else {
                    throw ContentError.invalid("\(lesson.id) 的 IPv4 基础课参数无效")
                }
            }
            if let mask = lesson.subnetMaskIntroduction {
                guard mask.isValid, lesson.ipv4Foundation == nil,
                      lesson.ipv4Introduction == nil, lesson.ipv4Visual == nil,
                      lesson.topology == nil,
                      lesson.explanation.isEmpty else {
                    throw ContentError.invalid("\(lesson.id) 的掩码入门参数无效")
                }
            }
            if let introduction = lesson.ipv4Introduction {
                guard IPv4AddressValue(ip: introduction.ip, prefix: 32) != nil,
                      lesson.ipv4Foundation == nil, lesson.ipv4Visual == nil,
                      lesson.topology == nil else {
                    throw ContentError.invalid("\(lesson.id) 的 IPv4 入门参数无效")
                }
            }
            if let visual = lesson.ipv4Visual {
                guard lesson.ipv4Foundation == nil, lesson.topology == nil,
                      visual.examples.count == 2,
                      visual.examples[0].mode == .explain,
                      visual.examples[1].mode == .practice,
                      visual.examples.allSatisfy({ IPv4AddressValue(ip: $0.ip, prefix: $0.prefix) != nil }),
                      visual.examples[1].prefix.isMultiple(of: 8),
                      (8...32).contains(visual.examples[1].prefix) else {
                    throw ContentError.invalid("\(lesson.id) 的 IPv4 可视化参数无效")
                }
            }
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
                if let pages = question.answerExplanation {
                    guard !pages.isEmpty, Set(pages.map(\.id)).count == pages.count,
                          pages.allSatisfy(\.isValid) else {
                        throw ContentError.invalid("\(lesson.id) 的答后图解不完整")
                    }
                }
            }
            let exercise = lesson.matching
            let left = Set(exercise.left.map(\.id))
            let right = Set(exercise.right.map(\.id))
            guard left.count == exercise.left.count, right.count == exercise.right.count,
                  !left.isEmpty, left.count == right.count,
                  Set(exercise.solution.keys) == left,
                  Set(exercise.solution.values) == right,
                  (!lesson.explanation.isEmpty || lesson.ipv4Foundation != nil ||
                   lesson.ipv4Introduction != nil || lesson.subnetMaskIntroduction != nil), !lesson.sources.isEmpty else {
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
