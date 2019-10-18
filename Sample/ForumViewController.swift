//
//  ForumViewController.swift
//  Sample
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Ballcap

struct Topic: Modelable, Codable, TopicProtocol {

    var title: String?

    var thumbnailImage: File?

    var isAvailable: Bool = true

    var isHidden: Bool = false
}

struct Post: Modelable, Codable, PostProtocol {

    var reply: DocumentReference?

    var from: String = ""

    var text: String?

    var image: File?

    var video: File?

    var audio: File?

    var location: GeoPoint?

    var sticker: String?

    var imageMap: [File] = []
}

class ForumViewController: Forum<Member, Topic, Post>.TopicsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.listen()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Topic", style: .done, target: self, action: #selector(addTopic))
    }

    @objc func addTopic() {
        let storyboard: UIStoryboard = UIStoryboard(name: "AddTopicViewController", bundle: nil)
        let viewController: AddTopicViewController = storyboard.instantiateInitialViewController() as! AddTopicViewController
        self.present(viewController, animated: true, completion: nil)
    }

    override func postsViewController(with topic: Document<Topic>) -> Forum<Member, Topic, Post>.PostsViewController {
        let viewController: PostViewController = PostViewController(topic: topic)
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }

}
