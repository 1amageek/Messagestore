//
//  RoomProtocol.swift
//  Messagestore
//
//  Created by 1amageek on 2018/07/31.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import FirebaseFirestore
import Ballcap

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
