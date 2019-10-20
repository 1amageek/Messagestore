//
//  AddTopicViewController.swift
//  Sample
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit
import Ballcap
import FirebaseFirestore
import FirebaseAuth

class AddTopicViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var addButton: UIButton!

    @IBAction func addAction(_ sender: Any) {
        guard let uid: String = Auth.auth().currentUser?.uid else { return }
        let topic: Document<Topic> = Document()
        topic.data?.title = textField.text
        let member: Document<Member> = Document(id: uid)
        Forum<Member, Topic, Post>.create(topic: topic, subscribers: [member])
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
