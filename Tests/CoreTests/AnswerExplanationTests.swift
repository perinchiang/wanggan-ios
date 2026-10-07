import XCTest
@testable import WangGanCore

final class AnswerExplanationTests: XCTestCase {
    private func homeLesson() throws -> Lesson {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let catalog = try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
        try catalog.validate()
        return try XCTUnwrap(catalog.lessons.first { $0.id == "home-two-boxes" })
    }

    private func solvedDraft(_ lesson: Lesson) -> LessonSession {
        var draft = LessonSession(lessonID: lesson.id)
        draft.stage = .challenge
        draft.answerSubmitted = true
        draft.selectedAnswer = lesson.question.correctID
        draft.matchingSubmitted = true
        draft.matchingSolved = true
        draft.challengeAnswer = lesson.challenge.correctID
        draft.challengeSubmitted = true
        draft.challengeSolved = true
        draft.mistakes = 2
        return draft
    }

    func testAnswerExplanationMustFinishBeforeCompletionAndAwardOnlyOnce() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        let pages = try XCTUnwrap(lesson.challenge.answerExplanation)
        var session = StepSession(lesson: lesson, from: solvedDraft(lesson))
        var legacy = solvedDraft(lesson)
        var ledger = ProgressLedger()
        for page in pages {
            plan.advance(&session)
            legacy.advance(lesson: lesson)
            XCTAssertEqual(legacy.challengeExplanationID, page.id)
            XCTAssertEqual(legacy.stage, .challenge)
            XCTAssertEqual(plan.answerExplanation(at: session.stepIndex)?.id, page.id)
            XCTAssertFalse(plan.isComplete(session))
            XCTAssertEqual(session.stageSession(lesson: lesson).stage, .challenge)
            XCTAssertEqual(ledger.complete(session.stageSession(lesson: lesson)), 0)
            XCTAssertTrue(ledger.lessons.isEmpty)
        }
        plan.advance(&session)
        legacy.advance(lesson: lesson)
        XCTAssertEqual(legacy.stage, .complete)
        XCTAssertTrue(plan.isComplete(session))
        let completed = session.stageSession(lesson: lesson)
        XCTAssertEqual(completed.stage, .complete)
        XCTAssertNil(completed.challengeExplanationID)
        XCTAssertEqual(ledger.complete(completed), 30)
        XCTAssertEqual(ledger.complete(completed), 30, "Repeated settlement returns its recorded reward")
        XCTAssertEqual(ledger.totalXP, 30)
    }

    func testEachPageRoundTripsThroughPersistedDraftWithoutResettingAnswer() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        var session = StepSession(lesson: lesson, from: solvedDraft(lesson))
        for page in lesson.challenge.answerExplanation ?? [] {
            plan.advance(&session)
            let data = try JSONEncoder().encode(session.stageSession(lesson: lesson))
            let saved = try JSONDecoder().decode(LessonSession.self, from: data)
            let restored = StepSession(lesson: lesson, from: saved)
            XCTAssertEqual(restored, session)
            XCTAssertEqual(saved.challengeExplanationID, page.id)
            XCTAssertEqual(restored.mistakes, 2)
            XCTAssertTrue(restored.challengeSolved)
        }
    }

    func testOldDraftAndOldCompletionDoNotLosePositionIdentityOrHistory() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        let old = solvedDraft(lesson)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        json.removeValue(forKey: "challengeExplanationID")
        let saved = try JSONDecoder().decode(LessonSession.self, from: JSONSerialization.data(withJSONObject: json))
        let restored = StepSession(lesson: lesson, from: saved)
        XCTAssertEqual(restored.id, old.id)
        XCTAssertEqual(restored.stepIndex, plan.challengeIndex)
        XCTAssertTrue(restored.challengeSolved)
        var completed = saved
        completed.stage = .complete
        let oldCompletion = StepSession(lesson: lesson, from: completed)
        XCTAssertTrue(plan.isComplete(oldCompletion), "New reading must not reopen completed courses")
        XCTAssertEqual(oldCompletion.id, completed.id)
    }

    func testUnsolvedAnswerCannotEnterOrAdvancePostAnswerReading() throws {
        let lesson = try homeLesson()
        let plan = LessonPlan(lesson: lesson)
        var old = solvedDraft(lesson)
        old.challengeSolved = false
        old.challengeExplanationID = lesson.challenge.answerExplanation?.last?.id
        var session = StepSession(lesson: lesson, from: old)
        XCTAssertEqual(session.stepIndex, plan.challengeIndex)
        plan.advance(&session)
        XCTAssertEqual(session.stepIndex, plan.challengeIndex)
        session.stepIndex += 1
        XCTAssertFalse(plan.canAdvance(session))
        XCTAssertFalse(plan.isComplete(session))
    }

    func testDiagramRejectsDuplicateConnectorsAndOpticalBranchesWithoutDownstreamPort() {
        let power = DevicePortConnection(id: "power", label: "电源口", medium: .power, destination: "电源")
        let fiber = DevicePortConnection(id: "pon", label: "光纤口", medium: .fiber, destination: "入户光纤")
        XCTAssertTrue(DevicePortsSpec(title: "一体机", ports: [power, fiber], fiberRooms: nil, note: "示意").isValid)
        XCTAssertFalse(DevicePortsSpec(title: "一体机", ports: [power, power, fiber], fiberRooms: nil, note: "示意").isValid)
        XCTAssertFalse(DevicePortsSpec(title: "FTTR", ports: [power, fiber], fiberRooms: ["房间一"], note: "示意").isValid)
    }

    func testTermOnlyPageIsValidWithoutDevicePortsAndRejectsMissingName() throws {
        let term = TermIntroduction(name: "FTTR", englishName: "Fiber to the Room", chineseName: "光纤到房间")
        let page = AnswerExplanation(id: "reveal", text: "故事之后揭晓名称", diagram: nil,
                                     homeNetwork: nil, termIntroduction: term)
        XCTAssertTrue(page.isValid)
        XCTAssertEqual(try JSONDecoder().decode(AnswerExplanation.self, from: JSONEncoder().encode(page)), page)
        XCTAssertFalse(TermIntroduction(name: "FTTR", englishName: " ", chineseName: "光纤到房间").isValid)
        XCTAssertFalse(AnswerExplanation(id: "empty", text: "没有图或卡片", diagram: nil,
                                        homeNetwork: nil, termIntroduction: nil).isValid)
    }

    func testRoomDiagramRejectsPowerAsNetworkCableAndSupportsOldPortOnlyContent() throws {
        let invalid = HomeNetworkSpec(title: "家", uplink: .fiber, uplinkLabel: "入户光纤",
                                      gatewayLabel: "主设备", roomMedium: .power, rooms: ["房间一"],
                                      roomDeviceLabel: "电脑", note: "示意")
        XCTAssertFalse(invalid.isValid)
        let lesson = try homeLesson()
        let page = try XCTUnwrap(lesson.challenge.answerExplanation?.first)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(page)) as? [String: Any])
        json.removeValue(forKey: "homeNetwork")
        json.removeValue(forKey: "termIntroduction")
        let old = try JSONDecoder().decode(AnswerExplanation.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(old.homeNetwork)
        XCTAssertNil(old.termIntroduction)
        XCTAssertTrue(old.isValid)
    }

    func testOldRoomContentDecodesWithoutAnOpticalModemNode() throws {
        let fixture = #"{"title":"接线示意","uplink":"ethernet","uplinkLabel":"光猫的网线","gatewayLabel":"路由器","roomMedium":"ethernet","rooms":["卧室"],"roomDeviceLabel":"电脑","note":"旧格式"}"#
        let old = try JSONDecoder().decode(HomeNetworkSpec.self, from: Data(fixture.utf8))
        XCTAssertNil(old.opticalModemLabel)
        XCTAssertEqual(old.uplink, .ethernet)
        XCTAssertTrue(old.isValid)
        XCTAssertEqual(try JSONDecoder().decode(HomeNetworkSpec.self, from: JSONEncoder().encode(old)), old)
    }

    func testStandaloneRouterDiagramIncludesSeparateOpticalAccess() throws {
        let lesson = try homeLesson()
        let page = try XCTUnwrap(lesson.challenge.answerExplanation?.first { $0.id == "router-ports" })
        let network = try XCTUnwrap(page.homeNetwork)
        XCTAssertNotNil(network.opticalModemLabel)
        XCTAssertEqual(network.uplink, .fiber)
        XCTAssertEqual(network.roomMedium, .ethernet)
        XCTAssertTrue(network.isValid)
        XCTAssertEqual(try JSONDecoder().decode(HomeNetworkSpec.self, from: JSONEncoder().encode(network)), network)
        for other in lesson.challenge.answerExplanation ?? [] where other.id != page.id {
            XCTAssertNil(other.homeNetwork?.opticalModemLabel)
        }
    }

    func testOpticalModemNodeRejectsEmptyNameAndNonFiberInput() {
        let empty = HomeNetworkSpec(title: "家", uplink: .fiber, uplinkLabel: "光纤",
                                    gatewayLabel: "路由器", roomMedium: .ethernet, rooms: ["卧室"],
                                    roomDeviceLabel: "电脑", note: "示意", opticalModemLabel: " ")
        let ethernet = HomeNetworkSpec(title: "家", uplink: .ethernet, uplinkLabel: "网线",
                                       gatewayLabel: "路由器", roomMedium: .ethernet, rooms: ["卧室"],
                                       roomDeviceLabel: "电脑", note: "示意", opticalModemLabel: "光猫")
        XCTAssertFalse(empty.isValid)
        XCTAssertFalse(ethernet.isValid)
    }
}
