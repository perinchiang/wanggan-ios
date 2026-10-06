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
    // Additive optional fields keep the original v1 ledger readable.
    var shortReviewDrafts: [String: ShortReviewSession]?
    var reviewEvidence: [ReviewAttempt]?
    // A newly inserted earlier lesson must not displace a farther main draft.
    var earlierDrafts: [String: LessonSession]?

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
        let saved = lessons[lessonID] == nil
            ? (draft?.lessonID == lessonID ? draft : earlierDrafts?[lessonID])
            : reviewDrafts?[lessonID]
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
                var earlier = earlierDrafts ?? [:]
                earlier[session.lessonID] = session
                earlierDrafts = earlier
                return
            }
            if let draft, draft.lessonID != session.lessonID, draft.stage != .complete,
               lessons[draft.lessonID] == nil {
                var earlier = earlierDrafts ?? [:]
                earlier[draft.lessonID] = draft
                earlierDrafts = earlier
            }
            earlierDrafts?.removeValue(forKey: session.lessonID)
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
        earlierDrafts = earlierDrafts?.filter {
            orderedIDs.contains($0.key) && lessons[$0.key] == nil &&
            $0.value.lessonID == $0.key && $0.value.stage != .complete
        }
    }

    private mutating func clearDraft(for session: LessonSession) {
        if draft?.id == session.id { draft = nil }
        if earlierDrafts?[session.lessonID]?.id == session.id {
            earlierDrafts?.removeValue(forKey: session.lessonID)
        }
        if reviewDrafts?[session.lessonID]?.id == session.id {
            reviewDrafts?.removeValue(forKey: session.lessonID)
        }
    }

    func isDue(_ id: String, now: Date = Date()) -> Bool {
        guard let progress = lessons[id] else { return false }
        return progress.nextReviewAt <= now
    }

    func isUnlocked(_ id: String, in orderedIDs: [String]) -> Bool {
        guard let index = orderedIDs.firstIndex(of: id) else { return false }
        if lessons[id] != nil { return true }
        if draft?.lessonID == id || earlierDrafts?[id] != nil { return true }
        return index == 0 || lessons[orderedIDs[index - 1]] != nil
    }

    @discardableResult
    mutating func complete(_ session: LessonSession, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let observed = session.observationCompleted == true && session.ipv4FoundationProgress?.finished == true
        guard session.stage == .complete, observed || (session.challengeSolved && session.matchingSolved) else { return 0 }
        clearDraft(for: session)
        return settle(sessionID: session.id, lessonID: session.lessonID, mistakes: session.mistakes,
                      independent: session.mistakes == 0, now: now, calendar: calendar)
    }

    private mutating func settle(sessionID: UUID, lessonID: String, mistakes: Int,
                                 independent: Bool, now: Date, calendar: Calendar) -> Int {
        if let reward = settledSessions[sessionID] { return reward }
        let day = calendar.startOfDay(for: now)
        let reward: Int
        if var previous = lessons[lessonID] {
            let firstPracticeToday = !calendar.isDate(previous.lastPracticedAt, inSameDayAs: now)
            reward = firstPracticeToday ? 5 : 0
            previous.lastPracticedAt = now
            previous.lastMistakes = mistakes
            let shortReviewErrorToday = (reviewEvidence ?? []).contains {
                $0.lessonID == lessonID && !$0.correct && calendar.isDate($0.submittedAt, inSameDayAs: now)
            }
            if !independent || shortReviewErrorToday {
                previous.reviewLevel = 0
                previous.nextReviewAt = calendar.date(byAdding: .day, value: 1, to: day) ?? now
            } else if firstPracticeToday {
                previous.reviewLevel = min(previous.reviewLevel + 1, 3)
                let interval = [1, 3, 7, 14][previous.reviewLevel]
                previous.nextReviewAt = calendar.date(byAdding: .day, value: interval, to: day) ?? now
            }
            lessons[lessonID] = previous
        } else {
            reward = 30
            lessons[lessonID] = LessonProgress(
                completedAt: now, lastPracticedAt: now,
                nextReviewAt: calendar.date(byAdding: .day, value: 1, to: day) ?? now,
                reviewLevel: 0, lastMistakes: mistakes
            )
        }
        settledSessions[sessionID] = reward
        totalXP += reward
        if !activityDays.contains(where: { calendar.isDate($0, inSameDayAs: now) }) {
            activityDays.append(day)
        }
        return reward
    }

    func shortSession(for lessonID: String, items: [ReviewItem]) -> ShortReviewSession? {
        guard lessons[lessonID] != nil else { return nil }
        let available = items.filter { $0.lessonID == lessonID }
        if let saved = shortReviewDrafts?[lessonID], available.contains(where: { saved.matches($0) }),
           settledSessions[saved.id] == nil { return saved }
        guard !available.isEmpty else { return nil }
        // A new session uses another scene; interrupted sessions keep the exact item.
        let lastItem = reviewEvidence?.last(where: { $0.lessonID == lessonID })?.itemID
        let nextIndex = available.firstIndex(where: { $0.id == lastItem }).map { ($0 + 1) % available.count } ?? 0
        return ShortReviewSession(item: available[nextIndex])
    }

    mutating func saveShortDraft(_ session: ShortReviewSession, items: [ReviewItem],
                                 calendar: Calendar = .current) {
        guard lessons[session.lessonID] != nil, settledSessions[session.id] == nil,
              let item = items.first(where: { session.matches($0) }) else { return }
        var drafts = shortReviewDrafts ?? [:]
        drafts[session.lessonID] = session
        shortReviewDrafts = drafts
        var evidence = reviewEvidence ?? []
        for attempt in session.attempts where !evidence.contains(where: { $0.id == attempt.id }) {
            guard attempt.sessionID == session.id, attempt.itemID == item.id,
                  attempt.contentRevision == item.revision, attempt.lessonID == item.lessonID,
                  attempt.knowledgePointID == item.knowledgePointID,
                  attempt.scenarioFamilyID == item.scenarioFamilyID,
                  item.options.contains(where: { $0.id == attempt.answerID }),
                  attempt.correct == (attempt.answerID == item.correctID) else { continue }
            evidence.append(attempt)
            if !attempt.correct, var previous = lessons[session.lessonID] {
                previous.reviewLevel = 0
                previous.lastMistakes = session.mistakes
                let day = calendar.startOfDay(for: attempt.submittedAt)
                previous.nextReviewAt = calendar.date(byAdding: .day, value: 1, to: day) ?? attempt.submittedAt
                lessons[session.lessonID] = previous
            }
        }
        reviewEvidence = evidence
    }

    @discardableResult
    mutating func completeShortReview(_ session: ShortReviewSession, items: [ReviewItem],
                                      now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard lessons[session.lessonID] != nil, let item = items.first(where: { session.matches($0) }),
              session.solved, session.selectedAnswer == item.correctID else { return 0 }
        if let reward = settledSessions[session.id] { return reward }
        saveShortDraft(session, items: items, calendar: calendar)
        let reward = settle(sessionID: session.id, lessonID: session.lessonID, mistakes: session.mistakes,
                            independent: session.independent, now: now, calendar: calendar)
        if shortReviewDrafts?[session.lessonID]?.id == session.id {
            shortReviewDrafts?.removeValue(forKey: session.lessonID)
        }
        return reward
    }

    func evidenceStatus(for knowledgePointID: String) -> ReviewEvidenceStatus {
        ReviewEvidenceStatus.summarize((reviewEvidence ?? []).filter { $0.knowledgePointID == knowledgePointID })
    }

    func activeDaysThisWeek(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return activityDays.filter { interval.contains($0) }.count
    }
}
