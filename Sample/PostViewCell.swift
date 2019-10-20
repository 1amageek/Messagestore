//
//  PostViewCell.swift
//  Messagestore
//
//  Created by 1amageek on 2019/10/20.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit

class PostViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.nameLabel.text = nil
        self.textLabel.text = nil
    }

}
