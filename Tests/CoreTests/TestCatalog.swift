import Foundation
@testable import WangGanCore

// Structural compatibility fixtures only. No retired lesson prose, sources or UI.
// Legacy IDs let regression tests exercise old persisted records. Never bundled.
enum TestCatalog {
    static func shipped() throws -> LessonCatalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode(LessonCatalog.self, from: Data(contentsOf: root.appendingPathComponent("Resources/lessons.json")))
    }
    static func compatibility() throws -> LessonCatalog {
        let fixture = try JSONDecoder().decode(LessonCatalog.self, from: Data(payload.utf8))
        let shipped = try shipped()
        return LessonCatalog(course: Course(id: "fixture", revision: 1, title: "Fixture",
            chapters: shipped.course.chapters + fixture.course.chapters,
            archivedLessonIDs: fixture.archivedLessonIDs),
            lessons: shipped.lessons + fixture.lessons, reviewItems: fixture.reviewItems)
    }
    private static let payload = #"""
    {
      "course": {
        "id": "wanggan-network-intuition",
        "revision": 5,
        "title": "Fixture text",
        "chapters": [
          {
            "id": "address-basics",
            "title": "Fixture text",
            "orderedLessonIDs": [
              "ipv4-address-role",
              "ipv4-address-format",
              "ipv4-octet-binary"
            ]
          },
          {
            "id": "first-look",
            "title": "Fixture text",
            "orderedLessonIDs": [
              "gateway",
              "subnet",
              "arp",
              "hop",
              "dns"
            ]
          }
        ],
        "archivedLessonIDs": [
          "ipv4-address",
          "subnet-mask"
        ]
      },
      "reviewItems": [
        {
          "id": "gateway.local-printer",
          "revision": 1,
          "lessonID": "gateway",
          "knowledgePointID": "ipv4.local-vs-gateway",
          "objective": "Fixture text",
          "scenarioFamilyID": "local-printer",
          "scene": "Fixture",
          "prompt": "Fixture text",
          "options": [
            {
              "id": "local",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "all-fail",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "slow",
              "text": "Fixture text",
              "feedback": "Fixture text"
            }
          ],
          "correctID": "local",
          "hint": "Fixture text",
          "explanation": "Fixture text"
        },
        {
          "id": "gateway.local-projector",
          "revision": 1,
          "lessonID": "gateway",
          "knowledgePointID": "ipv4.local-vs-gateway",
          "objective": "Fixture text",
          "scenarioFamilyID": "local-projector",
          "scene": "Fixture",
          "prompt": "Fixture text",
          "options": [
            {
              "id": "local",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "all-fail",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "internet",
              "text": "Fixture text",
              "feedback": "Fixture text"
            }
          ],
          "correctID": "local",
          "hint": "Fixture text",
          "explanation": "Fixture text"
        },
        {
          "id": "dns.uncached-name",
          "revision": 1,
          "lessonID": "dns",
          "knowledgePointID": "dns.resolution-vs-connectivity",
          "objective": "Fixture text",
          "scenarioFamilyID": "uncached-name",
          "scene": "Fixture",
          "prompt": "Fixture text",
          "options": [
            {
              "id": "ip",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "all-fail",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "all-work",
              "text": "Fixture text",
              "feedback": "Fixture text"
            }
          ],
          "correctID": "ip",
          "hint": "Fixture text",
          "explanation": "Fixture text"
        },
        {
          "id": "dns.cached-name",
          "revision": 1,
          "lessonID": "dns",
          "knowledgePointID": "dns.resolution-vs-connectivity",
          "objective": "Fixture text",
          "scenarioFamilyID": "cached-name",
          "scene": "Fixture",
          "prompt": "Fixture text",
          "options": [
            {
              "id": "cached",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "all-fail",
              "text": "Fixture text",
              "feedback": "Fixture text"
            },
            {
              "id": "forever",
              "text": "Fixture text",
              "feedback": "Fixture text"
            }
          ],
          "correctID": "cached",
          "hint": "Fixture text",
          "explanation": "Fixture text"
        }
      ],
      "lessons": [
        {
          "id": "ipv4-address-role",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "ipv4-foundation-role",
          "ipv4Foundation": {
            "kind": "addressRole",
            "ip": "192.168.1.23",
            "peerIP": "192.168.1.20"
          },
          "question": {
            "scene": [
              {
                "id": "lan-game",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "target",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "speed",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "room",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "target",
            "hint": "Fixture text"
          },
          "explanation": [],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "friend",
                "text": "Fixture text",
                "symbol": "desktopcomputer"
              },
              {
                "id": "xiaolin",
                "text": "Fixture text",
                "symbol": "laptopcomputer"
              }
            ],
            "right": [
              {
                "id": "23",
                "text": "Fixture text",
                "symbol": "number"
              },
              {
                "id": "31",
                "text": "Fixture text",
                "symbol": "number"
              }
            ],
            "solution": {
              "friend": "23",
              "xiaolin": "31"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "scene": [
              {
                "id": "new-network",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "current",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "identity",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "model",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "current",
            "hint": "Fixture text"
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "ipv4-address-format",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "ipv4-foundation-format",
          "ipv4Foundation": {
            "kind": "addressFormat",
            "ip": "192.168.1.23",
            "samples": [
              "192.168.1.23",
              "10.20.30.40",
              "172.16.0.8"
            ]
          },
          "question": {
            "scene": [
              {
                "id": "examples",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "four",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "devices",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "free",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "four",
            "hint": "Fixture text"
          },
          "explanation": [],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "octet",
                "text": "Fixture text",
                "symbol": "square"
              },
              {
                "id": "address",
                "text": "Fixture text",
                "symbol": "network"
              },
              {
                "id": "dot",
                "text": "Fixture text",
                "symbol": "circle.fill"
              }
            ],
            "right": [
              {
                "id": "segment",
                "text": "Fixture text",
                "symbol": "number"
              },
              {
                "id": "four-octets",
                "text": "Fixture text",
                "symbol": "square.grid.2x2"
              },
              {
                "id": "separator",
                "text": "Fixture text",
                "symbol": "line.3.horizontal"
              }
            ],
            "solution": {
              "octet": "segment",
              "address": "four-octets",
              "dot": "separator"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "scene": [
              {
                "id": "format-only",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "valid",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "three",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "five",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "valid",
            "hint": "Fixture text"
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "ipv4-octet-binary",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "ipv4-foundation-binary",
          "ipv4Foundation": {
            "kind": "octetBinary",
            "ip": "10.20.30.40",
            "focusOctet": 13
          },
          "question": {
            "scene": [
              {
                "id": "limit",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "ninth",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "digits",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "six",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "ninth",
            "hint": "Fixture text"
          },
          "explanation": [],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "zero",
                "text": "Fixture text",
                "symbol": "0.square"
              },
              {
                "id": "ten",
                "text": "Fixture text",
                "symbol": "10.square"
              },
              {
                "id": "max",
                "text": "Fixture text",
                "symbol": "number.square"
              }
            ],
            "right": [
              {
                "id": "d0",
                "text": "Fixture text",
                "symbol": "0.circle"
              },
              {
                "id": "d10",
                "text": "Fixture text",
                "symbol": "10.circle"
              },
              {
                "id": "d255",
                "text": "Fixture text",
                "symbol": "number.circle"
              }
            ],
            "solution": {
              "zero": "d0",
              "ten": "d10",
              "max": "d255"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "scene": [
              {
                "id": "convert",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "192",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "128",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "96",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "192",
            "hint": "Fixture text"
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "gateway",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "gateway",
          "question": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "all-fail",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "local",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "slow",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "local",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "home",
                "text": "Fixture text"
              },
              {
                "id": "wiring",
                "text": "Fixture text",
                "visual": "network"
              },
              {
                "id": "change",
                "text": "Fixture text"
              },
              {
                "id": "conditions",
                "text": "Fixture text"
              }
            ]
          },
          "explanation": [
            "Fixture text",
            "Fixture text",
            "Fixture text"
          ],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "nas",
                "text": "Fixture text",
                "symbol": "externaldrive"
              },
              {
                "id": "internet",
                "text": "Fixture text",
                "symbol": "globe"
              }
            ],
            "right": [
              {
                "id": "router",
                "text": "Fixture text",
                "symbol": "wifi.router"
              },
              {
                "id": "host",
                "text": "Fixture text",
                "symbol": "externaldrive"
              }
            ],
            "solution": {
              "nas": "host",
              "internet": "router"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "yes",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "no",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "yes",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "power",
                "text": "Fixture text"
              },
              {
                "id": "switch",
                "text": "Fixture text"
              },
              {
                "id": "conditions",
                "text": "Fixture text"
              }
            ]
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "subnet",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "subnet",
          "ipv4Visual": {
            "examples": [
              {
                "ip": "192.168.1.10",
                "prefix": 24,
                "mode": "explain"
              },
              {
                "ip": "10.20.30.40",
                "prefix": 16,
                "mode": "practice"
              }
            ]
          },
          "question": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "same",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "different",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "cable",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "different",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "encounter",
                "text": "Fixture text"
              },
              {
                "id": "addresses",
                "text": "Fixture text",
                "visual": "devices"
              },
              {
                "id": "mask",
                "text": "Fixture text"
              }
            ],
            "devices": [
              {
                "id": "a",
                "name": "Fixture text",
                "address": "192.168.1.10",
                "prefix": "/24"
              },
              {
                "id": "b",
                "name": "Fixture text",
                "address": "192.168.2.20",
                "prefix": "/24"
              }
            ]
          },
          "explanation": [
            "Fixture text",
            "Fixture text",
            "Fixture text"
          ],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "24",
                "text": "Fixture text",
                "symbol": "number"
              },
              {
                "id": "16",
                "text": "Fixture text",
                "symbol": "number"
              }
            ],
            "right": [
              {
                "id": "two",
                "text": "Fixture text",
                "symbol": "square.split.2x1"
              },
              {
                "id": "three",
                "text": "Fixture text",
                "symbol": "rectangle.split.3x1"
              }
            ],
            "solution": {
              "16": "two",
              "24": "three"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "yes",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "no",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "yes",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "change",
                "text": "Fixture text"
              },
              {
                "id": "mask",
                "text": "Fixture text",
                "visual": "devices"
              }
            ],
            "devices": [
              {
                "id": "a",
                "name": "Fixture text",
                "address": "192.168.1.10",
                "prefix": "/16"
              },
              {
                "id": "b",
                "name": "Fixture text",
                "address": "192.168.2.20",
                "prefix": "/16"
              }
            ]
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "arp",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "arp",
          "question": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "server",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "gateway",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "switch",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "gateway",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "destination",
                "text": "Fixture text"
              },
              {
                "id": "route",
                "text": "Fixture text"
              },
              {
                "id": "cache",
                "text": "Fixture text"
              }
            ]
          },
          "explanation": [
            "Fixture text",
            "Fixture text",
            "Fixture text"
          ],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "local",
                "text": "Fixture text",
                "symbol": "externaldrive"
              },
              {
                "id": "remote",
                "text": "Fixture text",
                "symbol": "globe"
              }
            ],
            "right": [
              {
                "id": "gwip",
                "text": "Fixture text",
                "symbol": "wifi.router"
              },
              {
                "id": "nasip",
                "text": "Fixture text",
                "symbol": "externaldrive"
              }
            ],
            "solution": {
              "local": "nasip",
              "remote": "gwip"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "no",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "yes",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "no",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "known",
                "text": "Fixture text"
              },
              {
                "id": "continue",
                "text": "Fixture text"
              }
            ]
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "hop",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "hop",
          "question": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "unchanged",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "frame",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "destination",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "frame",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "arrive",
                "text": "Fixture text"
              },
              {
                "id": "links",
                "text": "Fixture text"
              },
              {
                "id": "conditions",
                "text": "Fixture text"
              }
            ]
          },
          "explanation": [
            "Fixture text",
            "Fixture text",
            "Fixture text"
          ],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "ip",
                "text": "Fixture text",
                "symbol": "globe"
              },
              {
                "id": "mac",
                "text": "Fixture text",
                "symbol": "point.topleft.down.curvedto.point.bottomright.up"
              }
            ],
            "right": [
              {
                "id": "next",
                "text": "Fixture text",
                "symbol": "arrow.right"
              },
              {
                "id": "final",
                "text": "Fixture text",
                "symbol": "server.rack"
              }
            ],
            "solution": {
              "ip": "final",
              "mac": "next"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "yes",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "no",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "no",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "same",
                "text": "Fixture text"
              },
              {
                "id": "observe",
                "text": "Fixture text"
              }
            ]
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "dns",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "dns",
          "question": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "bandwidth",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "dns",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "cable",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "dns",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "ip",
                "text": "Fixture text"
              },
              {
                "id": "name",
                "text": "Fixture text"
              },
              {
                "id": "cache",
                "text": "Fixture text"
              }
            ]
          },
          "explanation": [
            "Fixture text",
            "Fixture text",
            "Fixture text"
          ],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "name",
                "text": "Fixture text",
                "symbol": "text.magnifyingglass"
              },
              {
                "id": "service",
                "text": "Fixture text",
                "symbol": "network"
              }
            ],
            "right": [
              {
                "id": "connect",
                "text": "Fixture text",
                "symbol": "arrow.left.arrow.right"
              },
              {
                "id": "resolve",
                "text": "Fixture text",
                "symbol": "character.book.closed"
              }
            ],
            "solution": {
              "name": "resolve",
              "service": "connect"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "prompt": "Fixture text",
            "options": [
              {
                "id": "yes",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "no",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "no",
            "hint": "Fixture text",
            "scene": [
              {
                "id": "outage",
                "text": "Fixture text"
              },
              {
                "id": "cache",
                "text": "Fixture text"
              }
            ]
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "ipv4-address",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "ipv4-address",
          "ipv4Introduction": {
            "ip": "192.168.1.10"
          },
          "question": {
            "scene": [
              {
                "id": "address",
                "text": "Fixture text"
              },
              {
                "id": "guess",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "bytes",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "devices",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "digits",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "bytes",
            "hint": "Fixture text"
          },
          "explanation": [],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "bit",
                "text": "Fixture text",
                "symbol": "circle.lefthalf.filled"
              },
              {
                "id": "octet",
                "text": "Fixture text",
                "symbol": "square.split.2x2"
              },
              {
                "id": "address",
                "text": "Fixture text",
                "symbol": "network"
              }
            ],
            "right": [
              {
                "id": "thirtytwo",
                "text": "Fixture text",
                "symbol": "number"
              },
              {
                "id": "zeroone",
                "text": "Fixture text",
                "symbol": "switch.2"
              },
              {
                "id": "eight",
                "text": "Fixture text",
                "symbol": "square.grid.2x2"
              }
            ],
            "solution": {
              "bit": "zeroone",
              "octet": "eight",
              "address": "thirtytwo"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "scene": [
              {
                "id": "change",
                "text": "Fixture text"
              },
              {
                "id": "scope",
                "text": "Fixture text"
              }
            ],
            "prompt": "Fixture text",
            "options": [
              {
                "id": "no",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "four",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "three",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "no",
            "hint": "Fixture text"
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        },
        {
          "id": "subnet-mask",
          "title": "Fixture text",
          "subtitle": "Fixture text",
          "takeaway": "Fixture text",
          "nextCuriosity": "Fixture text",
          "diagram": "subnet-mask",
          "subnetMaskIntroduction": {
            "ip": "10.20.30.40",
            "initialPrefix": 24,
            "alternatePrefix": 16,
            "practicePrefix": 8
          },
          "question": {
            "prompt": "Fixture text",
            "scene": [
              {
                "id": "card",
                "text": "Fixture text"
              },
              {
                "id": "missing",
                "text": "Fixture text"
              }
            ],
            "options": [
              {
                "id": "three",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "mask",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "mask",
            "hint": "Fixture text"
          },
          "explanation": [],
          "matching": {
            "prompt": "Fixture text",
            "left": [
              {
                "id": "one",
                "text": "Fixture text",
                "symbol": "1.circle"
              },
              {
                "id": "zero",
                "text": "Fixture text",
                "symbol": "0.circle"
              }
            ],
            "right": [
              {
                "id": "network",
                "text": "Fixture text",
                "symbol": "network"
              },
              {
                "id": "host",
                "text": "Fixture text",
                "symbol": "desktopcomputer"
              }
            ],
            "solution": {
              "one": "network",
              "zero": "host"
            },
            "explanation": "Fixture text"
          },
          "challenge": {
            "prompt": "Fixture text",
            "scene": [
              {
                "id": "before",
                "text": "Fixture text"
              },
              {
                "id": "change",
                "text": "Fixture text"
              }
            ],
            "options": [
              {
                "id": "three",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "same",
                "text": "Fixture text",
                "feedback": "Fixture text"
              },
              {
                "id": "identical",
                "text": "Fixture text",
                "feedback": "Fixture text"
              }
            ],
            "correctID": "same",
            "hint": "Fixture text"
          },
          "sources": [
            "https://example.invalid/fixture"
          ]
        }
      ]
    }
    """#
}
