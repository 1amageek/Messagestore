//
//  TranscriptProtocol.swift
//  Muni
//
//  Created by 1amageek on 2018/07/31.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import FirebaseFirestore
import Ballcap

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
