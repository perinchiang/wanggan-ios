import Foundation

struct LessonProgress: Codable, Equatable {
    var completedAt: Date
    var lastMistakes: Int
}

struct ProgressLedger: Codable, Equatable {
    var schemaVersion = 3
    var totalXP = 0
    var lessons: [String: LessonProgress] = [:]
    var activityDays: [Date] = []
    var settledSessions: [UUID: Int] = [:]
    var drafts: [String: LessonSession] = [:]
    var mainLessonID: String?

    var draft: LessonSession? { mainLessonID.flatMap { drafts[$0] } }
    var level: Int { totalXP / 100 + 1 }
    var levelProgress: Double { Double(totalXP % 100) / 100 }

    func recommendedLessonID(in orderedIDs: [String]) -> String? {
        guard let frontier = orderedIDs.firstIndex(where: { lessons[$0] == nil }) else {
            return orderedIDs.last
        }
        if let draft, draft.stage != .complete, lessons[draft.lessonID] == nil,
           let index = orderedIDs.firstIndex(of: draft.lessonID), index >= frontier {
            return draft.lessonID
        }
        return orderedIDs[frontier]
    }

    func hasDraft(for lessonID: String) -> Bool {
        guard let saved = drafts[lessonID] else { return false }
        return saved.lessonID == lessonID && saved.stage != .complete
    }

    func session(for lessonID: String) -> LessonSession {
        if hasDraft(for: lessonID), let saved = drafts[lessonID] { return saved }
        return LessonSession(lessonID: lessonID)
    }

    mutating func saveDraft(_ session: LessonSession, in orderedIDs: [String]) {
        guard orderedIDs.contains(session.lessonID) else { return }
        if session.stage == .complete {
            discardDraft(session)
            return
        }
        drafts[session.lessonID] = session
        // Reading a completed or earlier lesson does not displace an unfinished
        // lesson farther along the route. All sessions use the same draft store.
        guard lessons[session.lessonID] == nil else { return }
        if let main = draft, lessons[main.lessonID] == nil,
           let oldIndex = orderedIDs.firstIndex(of: main.lessonID),
           let newIndex = orderedIDs.firstIndex(of: session.lessonID), oldIndex > newIndex {
            return
        }
        mainLessonID = session.lessonID
    }

    // Missing content does not invalidate history. The active catalog filters
    // recommendation and opening a lesson, rather than deleting its saved data.
    mutating func normalizeDrafts(in orderedIDs: [String]) {
        drafts = drafts.filter { $0.key == $0.value.lessonID && $0.value.stage != .complete }
        if let id = mainLessonID, drafts[id] == nil || lessons[id] != nil {
            mainLessonID = nil
        }
    }

    mutating func discardDraft(_ session: LessonSession) {
        guard drafts[session.lessonID]?.id == session.id else { return }
        drafts.removeValue(forKey: session.lessonID)
        if mainLessonID == session.lessonID { mainLessonID = nil }
    }

    func isUnlocked(_ id: String, in orderedIDs: [String]) -> Bool {
        guard let index = orderedIDs.firstIndex(of: id) else { return false }
        if lessons[id] != nil || hasDraft(for: id) { return true }
        return index == 0 || lessons[orderedIDs[index - 1]] != nil
    }

    @discardableResult
    mutating func complete(_ session: LessonSession, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let observed = session.observationCompleted == true && session.ipv4FoundationProgress?.finished == true
        let finished: Bool
        if let practice = session.practice { finished = practice.isComplete && practice.attempt == PracticeAttempt() }
        else { finished = observed || (session.challengeSolved && session.matchingSolved) }
        guard session.stage == .complete, finished else { return 0 }
        discardDraft(session)
        if let reward = settledSessions[session.id] { return reward }

        let reward = lessons[session.lessonID] == nil ? 30 : 0
        if lessons[session.lessonID] == nil {
            lessons[session.lessonID] = LessonProgress(completedAt: now, lastMistakes: session.mistakes)
        }
        settledSessions[session.id] = reward
        totalXP += reward
        let day = calendar.startOfDay(for: now)
        if !activityDays.contains(where: { calendar.isDate($0, inSameDayAs: now) }) {
            activityDays.append(day)
        }
        return reward
    }

    func activeDaysThisWeek(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return activityDays.filter { interval.contains($0) }.count
    }
}
