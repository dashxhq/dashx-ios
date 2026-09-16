import XCTest
@testable import DashX

final class RealtimeCodecTests: XCTestCase {

    func testDecodesPingAndSubscriptionSucceeded() {
        guard case .ping? = DashXRealtimeCodec.decode(#"{"type":"PING"}"#) else {
            return XCTFail("expected ping")
        }
        let ack = DashXRealtimeCodec.decode(#"{"type":"SUBSCRIPTION_SUCCEEDED","data":{"channel":"in_app_chat:conversation:c1"}}"#)
        guard case .subscriptionSucceeded(let channel)? = ack else {
            return XCTFail("expected subscriptionSucceeded, got \(String(describing: ack))")
        }
        XCTAssertEqual(channel, "in_app_chat:conversation:c1")
    }

    func testDecodesChatMessageFrame() {
        let frame = DashXRealtimeCodec.decode("""
        {"type":"IN_APP_CHAT_MESSAGE","data":{
            "id":"m1","externalUid":"ext-1","conversationId":"c1","senderId":null,
            "aiRole":"USER","turnSeq":7,"renderedContent":{"text":"hi"},
            "createdAt":"2026-08-25 10:00:00","sentAt":"2026-08-25 10:00:00"
        }}
        """)
        guard case .inAppChatMessage(let message)? = frame else {
            return XCTFail("expected inAppChatMessage, got \(String(describing: frame))")
        }
        XCTAssertEqual(message.id, "m1")
        XCTAssertEqual(message.conversationId, "c1")
        XCTAssertEqual(message.turnSeq, 7)
        XCTAssertNil(message.senderId)
        XCTAssertEqual(message.aiRole, "USER")
        XCTAssertEqual(message.renderedContent["text"] as? String, "hi")
    }

    func testChatFrameMissingRequiredFieldsIsDropped() {
        XCTAssertNil(DashXRealtimeCodec.decode(#"{"type":"IN_APP_CHAT_MESSAGE","data":{"id":"m1"}}"#))
    }

    func testUnknownTypeDecodesToUnknownNotNil() {
        let frame = DashXRealtimeCodec.decode(#"{"type":"SOME_FUTURE_FRAME","data":{"x":1}}"#)
        guard case .unknown(let type, let data)? = frame else {
            return XCTFail("expected unknown, got \(String(describing: frame))")
        }
        XCTAssertEqual(type, "SOME_FUTURE_FRAME")
        XCTAssertEqual(data?["x"] as? Int, 1)
    }

    func testMalformedInputDecodesToNil() {
        XCTAssertNil(DashXRealtimeCodec.decode("not json"))
        XCTAssertNil(DashXRealtimeCodec.decode(#"{"noType":true}"#))
        XCTAssertNil(DashXRealtimeCodec.decode(""))
    }

    func testErrorFrameAcceptsNumericOrStringCode() {
        guard case .error(let code, let extensionCode, let message)? = DashXRealtimeCodec.decode(
            #"{"type":"ERROR","data":{"code":"4401","extensionCode":"UNAUTHORIZED","message":"nope"}}"#
        ) else { return XCTFail("expected error frame") }
        XCTAssertEqual(code, 4401)
        XCTAssertEqual(extensionCode, "UNAUTHORIZED")
        XCTAssertEqual(message, "nope")

        guard case .error(let numericCode, _, _)? = DashXRealtimeCodec.decode(#"{"type":"ERROR","data":{"code":4403}}"#) else {
            return XCTFail("expected error frame")
        }
        XCTAssertEqual(numericCode, 4403)
    }

    func testEncodesChannelFramesRoundTrip() {
        let subscribe = DashXRealtimeCodec.encodeChannelFrame(type: DashXRealtimeCodec.typeSubscribe, channelName: "in_app_chat:conversation:c1")
        let object = try? JSONSerialization.jsonObject(with: Data(subscribe.utf8)) as? [String: Any]
        XCTAssertEqual(object?["type"] as? String, "SUBSCRIBE")
        XCTAssertEqual((object?["data"] as? [String: Any])?["channelName"] as? String, "in_app_chat:conversation:c1")

        XCTAssertEqual(DashXRealtimeCodec.encodeBareFrame(type: DashXRealtimeCodec.typePong), #"{"type":"PONG"}"#)
    }
}
