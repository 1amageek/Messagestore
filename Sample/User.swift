//
//  User.swift
//  Sample
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import Ballcap

struct Member: Modelable, Codable, MemberProtocol {

    var name: String?

    var thumbnailImage: File?
}
