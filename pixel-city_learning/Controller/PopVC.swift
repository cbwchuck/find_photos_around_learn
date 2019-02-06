//
//  PopVC.swift
//  pixel-city_learning
//
//  Created by Chuck on 2018/5/13.
//  Copyright © 2018年 Chuck. All rights reserved.
//

import UIKit

class PopVC: UIViewController {

    @IBOutlet weak var popImageView: UIImageView!
    
    var popImage = UIImage()
    
    func initView(withImage image: UIImage){
        self.popImage = image
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(returnToMapView))
        doubleTap.numberOfTapsRequired = 2
//        popImageView.addGestureRecognizer(doubleTap) //错误用法, 无法正常使用，应该使用每个VC都有的，.view，如下所示
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func returnToMapView() {
        dismiss(animated: true, completion: nil)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = popImage
        addDoubleTap()
    }


    
    
    
    
}
