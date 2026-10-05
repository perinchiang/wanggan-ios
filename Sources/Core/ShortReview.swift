import Foundation

struct ReviewItem: Codable, Equatable, Identifiable {
    let id: String
    let revision: Int
    let lessonID: String
    let knowledgePointID: String
    let objective: String
    let scenarioFamilyID: String
    let scene: String
    let prompt: String
    let options: [AnswerOption]
    let correctID: String
    let hint: String
    let explanation: String
}

struct ReviewAttempt: Codable, Equatable, Identifiable {
    var id = UUID()
    let sessionID: UUID
    let itemID: String
    let contentRevision: Int
    let lessonID: String
    let knowledgePointID: String
    let scenarioFamilyID: String
    let submittedAt: Date
    let timeZoneID: String
    let answerID: String
    let correct: Bool
    let firstSubmission: Bool
    let usedHint: Bool

    var independent: Bool { correct && firstSubmission && !usedHint }
}

struct ShortReviewSession: Codable, Equatable, Identifiable {
    var id = UUID()
    let lessonID: String
    let itemID: String
    let contentRevision: Int
    var selectedAnswer: String?
    var usedHint = false
    var submitted = false
    var attempts: [ReviewAttempt] = []

    init(item: ReviewItem) {
        lessonID = item.lessonID
        itemID = item.id
        contentRevision = item.revision
    }

    var solved: Bool { submitted && attempts.last?.correct == true }
    var independent: Bool { solved && attempts.last?.independent == true }
    var mistakes: Int { attempts.filter { !$0.correct }.count }

    mutating func select(_ answerID: String, item: ReviewItem) {
        guard !submitted, matches(item), item.options.contains(where: { $0.id == answerID }) else { return }
        selectedAnswer = answerID
    }

    @discardableResult
    mutating func submit(item: ReviewItem, now: Date = Date(), calendar: Calendar = .current) -> ReviewAttempt? {
        guard !submitted, matches(item), let answer = selectedAnswer,
              item.options.contains(where: { $0.id == answer }) else { return nil }
        let attempt = ReviewAttempt(sessionID: id, itemID: itemID, contentRevision: contentRevision,
                                    lessonID: lessonID, knowledgePointID: item.knowledgePointID,
                                    scenarioFamilyID: item.scenarioFamilyID, submittedAt: now,
                                    timeZoneID: calendar.timeZone.identifier, answerID: answer,
                                    correct: answer == item.correctID, firstSubmission: attempts.isEmpty,
                                    usedHint: usedHint)
        attempts.append(attempt)
        submitted = true
        return attempt
    }

    mutating func retry() {
        guard submitted, !solved else { return }
        submitted = false
        selectedAnswer = nil
    }

    func matches(_ item: ReviewItem) -> Bool {
        item.id == itemID && item.lessonID == lessonID && item.revision == contentRevision
    }
}

enum ReviewEvidenceStatus: String {
    case none = "还没有短复习记录"
    case building = "这次在帮助下完成"
    case independent = "独立答对过"
    case delayed = "隔天换场景也答对"
    case needsPractice = "这次需要再巩固"

    static func summarize(_ evidence: [ReviewAttempt], calendar: Calendar = .current) -> Self {
        guard let latest = evidence.last else { return .none }
        if !latest.correct { return .needsPractice }
        if !latest.independent { return .building }
        let delayed = evidence.dropLast().contains {
            $0.independent && $0.scenarioFamilyID != latest.scenarioFamilyID &&
            latest.submittedAt.timeIntervalSince($0.submittedAt) >= 24 * 60 * 60 &&
            !calendar.isDate($0.submittedAt, inSameDayAs: latest.submittedAt)
        }
        return delayed ? .delayed : .independent
    }
}
