//
//  PostViewController.swift
//  Sample
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit

class PostViewController: Forum<Member, Topic, Post>.PostsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.listen()

    }

}
