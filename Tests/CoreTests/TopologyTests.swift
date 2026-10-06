import XCTest
@testable import WangGanCore

final class TopologyTests: XCTestCase {
    private func catalog() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }

    private func makeSpec(nodes: [TopologyNode], links: [TopologyLink], flow: [String],
                          summary: String = "示意图") -> TopologySpec {
        TopologySpec(nodes: nodes, links: links, flow: flow, accessibilitySummary: summary)
    }

    private let fiber = TopologyNode(id: "fiber", symbol: "cableconnector", label: "光纤", stage: 1, column: 0, row: 1)
    private let ont = TopologyNode(id: "ont", symbol: "externaldrive", label: "光猫", stage: 2, column: 1, row: 1)
    private let router = TopologyNode(id: "router", symbol: "wifi.router", label: "路由器", stage: 3, column: 2, row: 1)

    private var validLinks: [TopologyLink] {
        [TopologyLink(from: "fiber", to: "ont", stage: 2, wireless: nil),
         TopologyLink(from: "ont", to: "router", stage: 3, wireless: nil)]
    }

    func testValidSpecWithStagesAndFlow() {
        let spec = makeSpec(nodes: [fiber, ont, router], links: validLinks, flow: ["fiber", "ont", "router"])
        XCTAssertTrue(spec.isValid)
        XCTAssertEqual(spec.maxStage, 3)
        XCTAssertEqual(spec.flowStage, 3)
        XCTAssertEqual(spec.nodes(visibleAt: 1).map(\.id), ["fiber"])
        XCTAssertEqual(spec.links(visibleAt: 2).map(\.id), ["fiber-ont"])
        XCTAssertEqual(Set(spec.nodes(visibleAt: 3).map(\.id)), Set(["fiber", "ont", "router"]))
        XCTAssertEqual(spec.links(visibleAt: 2).count, 1)
        XCTAssertEqual(spec.links(visibleAt: 3).count, 2)
    }

    func testFlowStageFollowsLatestFlowNodeNotTheWholeDiagram() {
        let late = TopologyNode(id: "printer", symbol: "printer", label: "打印机", stage: 5, column: 3, row: 1)
        let spec = makeSpec(nodes: [fiber, ont, router, late], links: validLinks, flow: ["fiber", "ont", "router"])
        XCTAssertEqual(spec.maxStage, 5)
        XCTAssertEqual(spec.flowStage, 3, "The flow starts as soon as its own nodes are visible")
    }

    func testInvalidSpecs() {
        XCTAssertFalse(makeSpec(nodes: [fiber, fiber], links: validLinks, flow: ["fiber", "ont"]).isValid, "duplicate node ids")
        XCTAssertFalse(makeSpec(nodes: [fiber, ont, router],
                                links: [TopologyLink(from: "fiber", to: "ghost", stage: 1, wireless: nil)],
                                flow: ["fiber", "ont"]).isValid, "link to missing node")
        XCTAssertFalse(makeSpec(nodes: [fiber, ont, router], links: validLinks, flow: ["fiber", "ghost"]).isValid, "flow through missing node")
        XCTAssertFalse(makeSpec(nodes: [fiber, ont, router], links: validLinks, flow: ["fiber"]).isValid, "flow needs a path")
        XCTAssertFalse(makeSpec(nodes: [fiber, ont, router], links: validLinks, flow: ["fiber", "ont", "router"], summary: "").isValid, "summary required")
        XCTAssertFalse(makeSpec(nodes: [fiber, ont, router], links: [], flow: ["fiber", "ont", "router"]).isValid, "links required")
        XCTAssertFalse(makeSpec(nodes: [TopologyNode(id: "x", symbol: "x", label: "", stage: 1, column: 0, row: 0)],
                                 links: [TopologyLink(from: "x", to: "x", stage: 1, wireless: nil)], flow: ["x", "x"]).isValid, "self link and empty label")
    }

    func testShippedHomeTopologyRevealsWithinExplanationBudget() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "home-two-boxes" })
        let topology = try XCTUnwrap(lesson.topology)
        XCTAssertTrue(topology.isValid)
        XCTAssertLessThanOrEqual(topology.maxStage, lesson.explanation.count + 1)
        XCTAssertTrue(topology.flow.contains("router"), "The packet should traverse the home network")
        XCTAssertEqual(lesson.diagram, "home")
    }

    func testHomeLessonPlaysThroughStandardSteps() throws {
        let lesson = try XCTUnwrap(catalog().lessons.first { $0.id == "home-two-boxes" })
        let plan = LessonPlan(lesson: lesson)
        XCTAssertEqual(plan.steps.first?.kind, .conversation)
        XCTAssertEqual(plan.steps.last?.kind, .summary)
        XCTAssertEqual(plan.steps.filter { $0.kind == .text }.count, lesson.explanation.count)

        var session = StepSession(lessonID: lesson.id)
        for _ in 0..<plan.questionSceneCount { plan.advance(&session) }
        XCTAssertEqual(session.stepIndex, plan.questionIndex)
        plan.submitAnswer(lesson.question.correctID, in: &session)
        plan.advance(&session) // diagram step shows stage-1 nodes
        for _ in 0..<lesson.explanation.count { plan.advance(&session) }
        plan.advance(&session) // enter the matching step
        XCTAssertEqual(session.stepIndex, plan.matchingIndex)
        for (left, right) in lesson.matching.solution { plan.connect(left, to: right, in: &session) }
        plan.submitMatching(in: &session)
        XCTAssertTrue(session.matchingSolved)
        plan.advance(&session) // leave matching toward the challenge scene
        for _ in 0..<plan.challengeSceneCount { plan.advance(&session) }
        XCTAssertEqual(session.stepIndex, plan.challengeIndex)
        plan.submitChallenge(lesson.challenge.correctID, in: &session)
        plan.advance(&session)
        XCTAssertTrue(plan.isComplete(session))
        XCTAssertEqual(session.mistakes, 0)
    }

    func testCatalogRejectsTopologyBeyondExplanationBudget() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let url = root.appendingPathComponent("Resources/lessons.json")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        let lessons = try XCTUnwrap(json["lessons"] as? [[String: Any]])
        let index = try XCTUnwrap(lessons.firstIndex { $0["id"] as? String == "home-two-boxes" })
        let topology = try XCTUnwrap(lessons[index]["topology"] as? [String: Any])
        var nodes = try XCTUnwrap(topology["nodes"] as? [[String: Any]])
        nodes[0]["stage"] = 99
        var mutated = json
        var mutatedLessons = lessons
        var mutatedTopology = topology
        mutatedTopology["nodes"] = nodes
        mutatedLessons[index]["topology"] = mutatedTopology
        mutated["lessons"] = mutatedLessons

        let catalog = try JSONDecoder().decode(LessonCatalog.self, from: JSONSerialization.data(withJSONObject: mutated))
        XCTAssertThrowsError(try catalog.validate(), "A stage beyond the explanation budget must fail catalog validation")
    }
}
