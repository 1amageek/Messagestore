//
//  Room.swift
//  Sample
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import Ballcap
import Firebase

struct Room: Modelable, Codable , RoomProtocol {

    typealias TranscriptType = Transcript
    var name: String?
    var thumbnailImage: File?
    var members: [String] = []
    var recentTranscript: Transcript?
    var isMessagingEnabled: Bool = true
    var isHidden: Bool = false
    var lastViewedTimestamps: [String : Timestamp] = [:]
}
