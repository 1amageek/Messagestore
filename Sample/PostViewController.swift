//
//  PostViewController.swift
//  Sample
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit
import Ballcap
import Toolbar
import FirebaseAuth

class PostViewController: Forum<Member, Topic, Post>.PostsViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate {

    var senderID: String? {
        return Auth.auth().currentUser!.uid
    }

    /// Returns a CollectionView that displays posts.
    public private(set) var collectionView: UICollectionView!

    open func customLayout() -> UICollectionViewLayout {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 320)
        return layout
    }

    /// Returns the textView of inputAccessoryView.
    open var textView: UITextView = {
        let textView: UITextView = UITextView(frame: .zero)
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.layer.cornerRadius = 12
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1 / UIScreen.main.scale
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }()

    var sendBarItem: ToolbarItem!

    open override func loadView() {
        super.loadView()
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.customLayout())
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.register(UINib(nibName: "PostViewCell", bundle: nil), forCellWithReuseIdentifier: "PostViewCell")
        self.view.addSubview(self.collectionView)
        if #available(iOS 13.0, *) {
             self.view.backgroundColor = UIColor.systemBackground
             self.collectionView.backgroundColor = UIColor.systemBackground
        } else {
            self.view.backgroundColor = UIColor.white
            self.collectionView.backgroundColor = UIColor.white
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.delegate = self
        self.sendBarItem = ToolbarItem(title: "Send", target: self, action: #selector(send))
        self.toolBar.setItems([ToolbarItem(customView: self.textView), self.sendBarItem], animated: false)
        self.posts.onChanged { [weak self] (_, snapshot) in
            self?.collectionView.reloadData()
        }
        self.listen()
    }

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PostViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostViewCell", for: indexPath) as! PostViewCell
        let post: Document<Post> = self.posts![indexPath.item]
        cell.textLabel.text = post.data?.text
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 120)
    }

    public var toolBar: Toolbar = Toolbar()

    open var scrollsToBottomOnKeybordBeginsEditing: Bool = false

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override var inputAccessoryView: UIView? {
        return self.toolBar
    }

    open override var shouldAutorotate: Bool {
        return false
    }

    internal var constraint: NSLayoutConstraint?

    internal var isFirstFetching: Bool = true

    internal var collectionViewBottomInset: CGFloat = 0 {
        didSet {
            self.collectionView.contentInset.bottom = collectionViewBottomInset
            self.collectionView.scrollIndicatorInsets.bottom = collectionViewBottomInset
        }
    }

    internal var keyboardOffsetFrame: CGRect {
        guard let inputFrame = inputAccessoryView?.frame else { return .zero }
        return CGRect(origin: inputFrame.origin, size: CGSize(width: inputFrame.width, height: inputFrame.height))
    }

    internal func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    internal func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    open override func viewWillLayoutSubviews() {
        self.collectionView.frame = self.view.bounds
    }

    open override func viewDidLayoutSubviews() {
        self.collectionViewBottomInset = keyboardOffsetFrame.height
    }



    // MARK: -

    @objc internal func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let newBottomInset: CGFloat = self.view.frame.height - keyboardEndFrame.minY + self.view.frame.origin.y
        collectionViewBottomInset = newBottomInset
    }

    @objc
    public func send() {
        guard let senderID: String = self.senderID else {
            fatalError("[Messagestore] error: You need to override senderID.")
        }
        guard let text: String = self.textView.text else { return }
        let post: Document<Post> = Document()
        post.data?.from = senderID
        post.data?.text = text
        Forum<Member, Topic, Post>.post(post, to: self.topic)
    }

    // MARK: -

    open func textViewDidBeginEditing(_ textView: UITextView) {

    }

    open func textViewDidChange(_ textView: UITextView) {
        let size: CGSize = textView.sizeThatFits(textView.bounds.size)
        textView.isScrollEnabled = size.height > self.toolBar.maximumHeight
        if let constraint: NSLayoutConstraint = self.constraint {
            textView.removeConstraint(constraint)
        }
        self.constraint = textView.heightAnchor.constraint(equalToConstant: size.height)
        self.constraint?.priority = .defaultHigh
        self.constraint?.isActive = true
    }

    open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }

    deinit {
        self.removeKeyboardObservers()
    }
}
