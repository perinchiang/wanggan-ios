import Foundation

struct LessonProgress: Codable, Equatable {
    var completedAt: Date
    var lastPracticedAt: Date
    var nextReviewAt: Date
    var reviewLevel: Int
    var lastMistakes: Int
}

struct ProgressLedger: Codable, Equatable {
    var schemaVersion = 1
    var totalXP = 0
    var lessons: [String: LessonProgress] = [:]
    var activityDays: [Date] = []
    var settledSessions: [UUID: Int] = [:]
    var draft: LessonSession?
    // Optional so progress written before review drafts existed still decodes.
    var reviewDrafts: [String: LessonSession]?

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

    func session(for lessonID: String) -> LessonSession {
        let saved = lessons[lessonID] == nil ? draft : reviewDrafts?[lessonID]
        if let saved, saved.lessonID == lessonID, saved.stage != .complete { return saved }
        return LessonSession(lessonID: lessonID)
    }

    mutating func saveDraft(_ session: LessonSession, in orderedIDs: [String]) {
        guard orderedIDs.contains(session.lessonID) else { return }
        if session.stage == .complete {
            clearDraft(for: session)
        } else if lessons[session.lessonID] != nil {
            var reviews = reviewDrafts ?? [:]
            reviews[session.lessonID] = session
            reviewDrafts = reviews
        } else {
            // Reopening an earlier lesson must not replace a farther main-course draft.
            if let draft, let oldIndex = orderedIDs.firstIndex(of: draft.lessonID),
               let newIndex = orderedIDs.firstIndex(of: session.lessonID), oldIndex > newIndex {
                return
            }
            draft = session
        }
    }

    mutating func normalizeDrafts(in orderedIDs: [String]) {
        if let saved = draft {
            if !orderedIDs.contains(saved.lessonID) || saved.stage == .complete {
                draft = nil
            } else if lessons[saved.lessonID] != nil {
                // Older builds put a review in the main-course slot.
                var reviews = reviewDrafts ?? [:]
                if reviews[saved.lessonID] == nil { reviews[saved.lessonID] = saved }
                reviewDrafts = reviews
                draft = nil
            }
        }
        reviewDrafts = reviewDrafts?.filter {
            orderedIDs.contains($0.key) && lessons[$0.key] != nil &&
            $0.value.lessonID == $0.key && $0.value.stage != .complete
        }
    }

    private mutating func clearDraft(for session: LessonSession) {
        if draft?.id == session.id { draft = nil }
        if reviewDrafts?[session.lessonID]?.id == session.id {
            reviewDrafts?.removeValue(forKey: session.lessonID)
        }
    }

    func isDue(_ id: String, now: Date = Date()) -> Bool {
        guard let progress = lessons[id] else { return false }
        return progress.nextReviewAt <= now
    }

    @discardableResult
    mutating func complete(_ session: LessonSession, now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard session.stage == .complete, session.challengeSolved, session.matchingSolved else { return 0 }
        clearDraft(for: session)
        if let reward = settledSessions[session.id] { return reward }
        let day = calendar.startOfDay(for: now)
        let reward: Int
        if var previous = lessons[session.lessonID] {
            let firstPracticeToday = !calendar.isDate(previous.lastPracticedAt, inSameDayAs: now)
            reward = firstPracticeToday ? 5 : 0
            previous.lastPracticedAt = now
            previous.lastMistakes = session.mistakes
            if session.mistakes > 0 {
                previous.reviewLevel = 0
                previous.nextReviewAt = calendar.date(byAdding: .day, value: 1, to: day) ?? now
            } else if firstPracticeToday {
                previous.reviewLevel = min(previous.reviewLevel + 1, 3)
                let interval = [1, 3, 7, 14][previous.reviewLevel]
                previous.nextReviewAt = calendar.date(byAdding: .day, value: interval, to: day) ?? now
            }
            lessons[session.lessonID] = previous
        } else {
            reward = 30
            lessons[session.lessonID] = LessonProgress(
                completedAt: now, lastPracticedAt: now,
                nextReviewAt: calendar.date(byAdding: .day, value: 1, to: day) ?? now,
                reviewLevel: 0, lastMistakes: session.mistakes
            )
        }
        settledSessions[session.id] = reward
        totalXP += reward
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
