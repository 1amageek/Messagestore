//
//  Subscription.swift
//  Messagestore
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import FirebaseFirestore
import Ballcap

public struct Subscription: Modelable, Codable {

    public var topic: DocumentReference!

    public var isHidden: Bool = false

    public init() { }

    public init(topic: DocumentReference) {
        self.topic = topic
    }
}
