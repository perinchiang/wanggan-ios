import Foundation

enum PracticeRole: String, Codable { case exploration, mastery }
enum PracticeKind: String, Codable { case choice, fillBlank, matching }
enum ConnectionMedium: String, Codable { case ethernet, wifi }
enum ConnectionDevice: String, Codable {
    case desktop, laptop, phone
    var symbol: String {
        switch self {
        case .desktop: return "desktopcomputer"
        case .laptop: return "laptopcomputer"
        case .phone: return "iphone"
        }
    }
    var name: String { self == .phone ? "手机" : "电脑" }
}

struct ConnectionFigure: Codable, Equatable, Identifiable {
    let id: String
    let device: ConnectionDevice
    let medium: ConnectionMedium
    let caption: String?
    let showMediumLabel: Bool
}

struct PracticeQuestion: Codable, Equatable, Identifiable {
    let id: String
    let role: PracticeRole
    let kind: PracticeKind
    let prompt: String
    let figures: [ConnectionFigure]
    let options: [AnswerOption]
    let correctID: String?
    let matching: MatchingExercise?
    let explanation: String

    var answerText: String {
        if let exercise = matching {
            return exercise.left.compactMap { item in
                guard let target = exercise.right.first(where: { $0.id == exercise.solution[item.id] }) else { return nil }
                return "\(item.text) → \(target.text)"
            }.joined(separator: "；")
        }
        return options.first(where: { $0.id == correctID })?.text ?? ""
    }

    var isValid: Bool {
        guard !id.isEmpty, !prompt.isEmpty, !explanation.isEmpty,
              Set(figures.map(\.id)).count == figures.count else { return false }
        if kind == .matching {
            guard let matching, options.isEmpty, correctID == nil else { return false }
            let left = Set(matching.left.map(\.id)), right = Set(matching.right.map(\.id))
            return (2...3).contains(left.count) && left.count == matching.left.count &&
                right.count == matching.right.count && left.count == right.count &&
                Set(matching.solution.keys) == left && Set(matching.solution.values) == right
        }
        return matching == nil && options.count >= 2 &&
            Set(options.map(\.id)).count == options.count &&
            options.allSatisfy { !$0.id.isEmpty && !$0.text.isEmpty } &&
            options.contains { $0.id == correctID } &&
            (kind != .fillBlank || prompt.components(separatedBy: "____").count == 2)
    }
}

struct PracticeLesson: Codable, Equatable {
    let revision: Int
    let questions: [PracticeQuestion]
    var isValid: Bool {
        revision > 0 && !questions.isEmpty && questions.allSatisfy(\.isValid) &&
            Set(questions.map(\.id)).count == questions.count
    }
    func question(_ id: String?) -> PracticeQuestion? { questions.first { $0.id == id } }
}

/// One question's evidence. Correct matches survive interruption; selection
/// animations live in SwiftUI and never consume an attempt.
struct PracticeAttempt: Codable, Equatable {
    var selectedID: String?
    var matches: [String: String] = [:]
    var matchingErrors = 0
    var result: Bool?

    mutating func select(_ id: String, question: PracticeQuestion) {
        guard result == nil, question.kind != .matching,
              question.options.contains(where: { $0.id == id }) else { return }
        if question.kind == .fillBlank { selectedID = selectedID == id ? nil : id }
        else { selectedID = id; submit(question) }
    }

    mutating func submit(_ question: PracticeQuestion) {
        guard result == nil, question.kind != .matching, let selectedID,
              question.options.contains(where: { $0.id == selectedID }) else { return }
        result = selectedID == question.correctID
    }

    @discardableResult
    mutating func pair(_ left: String, _ right: String, question: PracticeQuestion) -> Bool {
        guard result == nil, let exercise = question.matching,
              exercise.left.contains(where: { $0.id == left }),
              exercise.right.contains(where: { $0.id == right }),
              matches[left] == nil, !matches.values.contains(right) else { return false }
        guard exercise.solution[left] == right else {
            matchingErrors += 1
            if matchingErrors == 3 { result = false }
            return false
        }
        matches[left] = right
        if matches.count == exercise.left.count { result = true }
        return true
    }
}

/// Stable question IDs, not screen positions. A failed mastery question moves
/// to the tail only when Continue is pressed, while its feedback stays visible.
struct PracticeSession: Codable, Equatable {
    let revision: Int
    var queue: [String]
    var attempt = PracticeAttempt()
    var completedIDs: Set<String> = []
    var mistakes = 0
    /// A previously answered item separates the last error from its retry.
    /// It grants no extra credit and is not a different learning route.
    var interludeID: String?

    init(lesson: PracticeLesson) {
        revision = lesson.revision
        queue = lesson.questions.map(\.id)
    }
    var currentID: String? { queue.first }
    var isComplete: Bool { queue.isEmpty }

    mutating func advance(lesson: PracticeLesson) {
        guard let question = lesson.question(currentID), let result = attempt.result else { return }
        queue.removeFirst()
        interludeID = nil
        if !result && question.role == .mastery {
            mistakes += 1
            completedIDs.remove(question.id)
            if queue.isEmpty,
               let separator = lesson.questions.first(where: {
                   $0.id != question.id && $0.role == .mastery && completedIDs.contains($0.id)
               }) {
                interludeID = separator.id
                queue.append(separator.id)
            }
            queue.append(question.id)
        } else {
            completedIDs.insert(question.id)
        }
        attempt = PracticeAttempt()
    }

    func isValid(for lesson: PracticeLesson) -> Bool {
        let ids = Set(lesson.questions.map(\.id))
        guard revision == lesson.revision, Set(queue).count == queue.count,
              Set(queue).isSubset(of: ids), completedIDs.isSubset(of: ids),
              Set(queue).union(completedIDs) == ids,
              Set(queue).intersection(completedIDs) == Set(interludeID.map { [$0] } ?? []),
              interludeID.map({ $0 == queue.first && completedIDs.contains($0) }) ?? true,
              mistakes >= 0 else { return false }
        guard let question = lesson.question(currentID) else {
            return queue.isEmpty && attempt == PracticeAttempt()
        }
        if question.kind == .matching, let exercise = question.matching {
            return (0...3).contains(attempt.matchingErrors) && attempt.selectedID == nil &&
                attempt.matches.allSatisfy { exercise.solution[$0.key] == $0.value } &&
                (attempt.result == nil ? attempt.matchingErrors < 3 && attempt.matches.count < exercise.left.count :
                    attempt.result == true ? attempt.matches == exercise.solution && attempt.matchingErrors < 3 :
                    attempt.matchingErrors == 3 && attempt.matches.count < exercise.left.count)
        }
        guard attempt.matches.isEmpty, attempt.matchingErrors == 0,
              attempt.selectedID.map({ id in question.options.contains { $0.id == id } }) ?? true else { return false }
        if let result = attempt.result {
            return attempt.selectedID != nil && result == (attempt.selectedID == question.correctID)
        }
        return question.kind == .fillBlank || attempt.selectedID == nil
    }
}
