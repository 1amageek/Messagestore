//
//  Message.swift
//  Messagestore
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import Ballcap
import FirebaseFirestore

/**
 Messagestore is the core class of chat function.

 In order to use the chat function, it is necessary to conform to the protocol of
 User Protocol, Room Protocol, Transcript Protocol.
 */
open class Message<
    MemberType: MemberProtocol & Modelable & Codable,
    RoomType: RoomProtocol & Modelable & Codable,
    TranscriptType: Modelable & Codable
    >: NSObject where RoomType.TranscriptType == TranscriptType
{ }

/**
 Define the properties that the `Room` object should have.
 */
public protocol RoomProtocol {

    associatedtype TranscriptType: TranscriptProtocol

    /// It is the display name of the room.
    var name: String? { get set }

    /// It is the thumbnail image of the room.
    var thumbnailImage: File? { get set }

    /// It is a member who can see the conversation.
    var members: [String] { get set }

    /// It holds the last Transcript.
    var lastTranscript: TranscriptType? { get set }

    /// It is the timestamp when the last Transcript was received.
    var lastTranscriptReceivedAt: ServerTimestamp { get set }

    /// Returns if message is possible. default true.
    var isMessagingEnabled: Bool { get set }

    /// If it is false, it is not displayed in InBoxViewController.
    var isHidden: Bool { get set }
}

/**
 Define the properties that the `Transcript` object should have.
 */
public protocol TranscriptProtocol {

    /// Set the room's ID.
    var to: String { get set }

    /// Set the sender's ID.
    var from: String { get set }

    // MARK: -

    /// Text content
    var text: String? { get set }

    /// Text content
    var image: File? { get set }

    /// Video content
    var video: File? { get set }

    /// Audio content
    var audio: File? { get set }

    /// Location content
    var location: GeoPoint? { get set }

    /// Sticker content
    var sticker: String? { get set }

    /// Image map content
    var imageMap: [File] { get set }
}
