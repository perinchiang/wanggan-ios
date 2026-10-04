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

    var level: Int { totalXP / 100 + 1 }
    var levelProgress: Double { Double(totalXP % 100) / 100 }

    func isDue(_ id: String, now: Date = Date()) -> Bool {
        guard let progress = lessons[id] else { return false }
        return progress.nextReviewAt <= now
    }

    @discardableResult
    mutating func complete(_ session: LessonSession, now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard session.stage == .complete, session.challengeSolved, session.matchingSolved else { return 0 }
        if let reward = settledSessions[session.id] { return reward }
        let day = calendar.startOfDay(for: now)
        let reward: Int
        if var previous = lessons[session.lessonID] {
            reward = calendar.isDate(previous.lastPracticedAt, inSameDayAs: now) ? 0 : 5
            if reward > 0 {
                previous.reviewLevel = session.mistakes == 0 ? min(previous.reviewLevel + 1, 3) : 0
                previous.lastPracticedAt = now
                previous.lastMistakes = session.mistakes
                let interval = [1, 3, 7, 14][previous.reviewLevel]
                previous.nextReviewAt = calendar.date(byAdding: .day, value: interval, to: day) ?? now
                lessons[session.lessonID] = previous
            }
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
