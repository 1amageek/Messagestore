//
//  Transcript.swift
//  Sample
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import Ballcap
import FirebaseFirestore

struct Transcript: Modelable, Codable, TranscriptProtocol {

    var to: String = ""

    var from: String = ""

    var text: String?

    var image: File?

    var video: File?

    var audio: File?

    var location: GeoPoint?

    var sticker: String?

    var imageMap: [File] = []
}
