//
//  ViewController.swift
//  DepthControl
//
//  Created by Harlan Haskins on 4/20/18.
//  Copyright © 2018 Harlan Haskins. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DepthReaderDelegate {
  @IBOutlet var imageView: UIImageView!

  let reader = DepthReader()

  override func viewDidLoad() {
    super.viewDidLoad()

    reader.delegate = self
  }

  func depthReader(_ depthReader: DepthReader, didOutputDepthImage image: CIImage) {
    imageView.image = UIImage(ciImage: image)
  }
}

