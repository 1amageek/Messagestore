//
//  ViewController.swift
//  Sample
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import UIKit
import Ballcap
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var idField: UITextField!

    @IBOutlet weak var textField: UITextField!
    @IBAction func addRoom(_ sender: Any) {

        guard let user: FirebaseAuth.User = Auth.auth().currentUser else { return }

        guard let userID: String = textField.text else { return }

        let batch: Batch = Batch()
        let room: Document<Room> = Document()
        room[\.members] = [userID, user.uid]
        room[\.members]?.forEach({ (uid) in
            let ref: DocumentReference = room.documentReference.collection("members").document(uid)
            let member: Document<User> = Document(ref)
            member.data = User()
            batch.save(member)
        })
        batch.save(room)
        batch.commit { [weak self] (error) in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        }
        guard let user: FirebaseAuth.User = Auth.auth().currentUser else { return }
        self.idField.text = user.uid

        print("**************************************")
        print("YOUR ID: ", user.uid)
        print("**************************************")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
