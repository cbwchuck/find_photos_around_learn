//
//  ViewController.swift
//  pixel-city_learning
//
//  Created by Chuck on 2018/5/10.
//  Copyright © 2018年 Chuck. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let radiusRegion: Double = 1000
    var spinner = UIActivityIndicatorView()
    var progressLabel = UILabel()
    let screenSize = UIScreen.main.bounds
    
    //programmatically create Collection View
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    var imageURLArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //两个代理，不像Table View一样强制需要implement函数
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCC.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        pullUpView.addSubview(collectionView!)
        collectionView?.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        
        registerForPreviewing(with: self, sourceView: collectionView!)
    }

    func addDoubleTap () {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin)) //在#selector中，传参默认设置为自己
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }

    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    @objc func swipeViewDown() {
        cancelAllSession()
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func navigateButtonPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    func addSpinner() {
        spinner.center = CGPoint(x: screenSize.width/2 - spinner.frame.width/2, y: 150 - spinner.frame.height/2)
        spinner.activityIndicatorViewStyle = .whiteLarge
        spinner.color = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        spinner.startAnimating()
//        pullUpView.addSubview(spinner)
        collectionView?.addSubview(spinner)
    }
    
    //将Spinner删除
    func removeSpinner() {
        spinner.removeFromSuperview()
    }
    
    func addProgressLabel() {
        progressLabel.frame = CGRect(x: screenSize.width/2 - 120, y: 175, width: 240, height: 40)
        progressLabel.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel.textAlignment = .center
        progressLabel.textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
//        progressLabel.text = "Hi!"
//        pullUpView.addSubview(progressLabel)
        collectionView?.addSubview(progressLabel  )
    }
    
    func removeProgressLabel() {
        progressLabel.removeFromSuperview()
    }
}

extension MapVC: MKMapViewDelegate {
    //这个函数使地图自动将中心放大到离我所在的位置半径1000米的位置
    func centerMapOnUserLocation() {
        //防止有时候加载位置时可能因为各种原因加载不出来，所以做optional unwrap
        guard let coordinate = locationManager.location? .coordinate else {return}
        //通过这个函数设置范围
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, radiusRegion*2, radiusRegion*2)//*2是因为左右上下都为1000m
        //将视图转到设定的位置
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer){
        //不让多个pin同时出现
        removePin()
        //不让多个Spinner同时出现
        removeSpinner()
        //不让多个Label同时出现
        removeProgressLabel()
        //不让在移到新的位置后还在加载原先位置的数据
        cancelAllSession()

        imageArray = []
        imageURLArray = []
        self.collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLabel()
        //获取点击的位置
        let touchPoint = sender.location(in: mapView)
        //将点击的位置转换为GPS位置
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordiante: touchCoordinate, identifier: "DroppablePin")
        mapView.addAnnotation(annotation)
        
        print(getFlickrUrl(forKey: apiKey, forAnnotation: annotation, andNumberOfPhots: numberOfPhotsPerPage))
        
        //让pin在屏幕中间显示,和上面的函数中采用的手法相同
        let coordinationRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, radiusRegion, radiusRegion)
        mapView.setRegion(coordinationRegion, animated: true)
        
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImages(handler: { (finished) in
                    if finished {
                        self.removeSpinner()
                        self.removeProgressLabel()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    //更改pin的属性
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //不让用户位置的小圆点也变成针
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "DroppablePin")
        pinAnnotation.tintColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
        //"indicating whether the annotation view is animated onto the screen."
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func animateViewUp() {
        
//        mapViewBottomConstraint.constant = 300
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()//将在0.3秒内更新完界面
        }
    }
    
    func retrieveUrls(forAnnotation annotation:DroppablePin, handler: @escaping(_ status: Bool)->()) {
//        imageURLArray = []
        
        Alamofire.request(getFlickrUrl(forKey: apiKey, forAnnotation: annotation, andNumberOfPhots: numberOfPhotsPerPage)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else {return}
            let photosDictionary = json["photos"] as! Dictionary<String, AnyObject>
            let photoDictionaryArray = photosDictionary["photo"] as! [Dictionary<String, AnyObject>]
            for everyPhoto in photoDictionaryArray {
                let postUrl = "https://farm\(everyPhoto["farm"]!).staticflickr.com/\(everyPhoto["server"]!)/\(everyPhoto["id"]!)_\(everyPhoto["secret"]!)_h_d.jpg"
                self.imageURLArray.append(postUrl)
            }
            handler(true)
        }
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool)->()){
//        imageArray = []
        
        for url in imageURLArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else {return}
                self.imageArray.append(image)
                self.progressLabel.text = "\(self.imageArray.count)/\(numberOfPhotsPerPage) Images Downloaded"
                if self.imageArray.count == numberOfPhotsPerPage {
                    handler(true)
                }
            })
        }
    }
    
    func cancelAllSession() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({$0.cancel()})// 相当于 for task in sessionTask {task.cancel}
            uploadData.forEach({$0.cancel()})
            downloadData.forEach({$0.cancel()})
        }
    }
    
}

extension MapVC: CLLocationManagerDelegate {
    //这个函数用来检查是否有使用位置的权限
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return //退出函数
        }
    }
    
    //每当使用权限改变时，这个函数会被调用
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCC else {return UICollectionViewCell()}
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //number of items in array
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: popVCIdentifier) as? PopVC else
        {return}
        popVC.initView(withImage: imageArray[indexPath.row])
        //To present a view controller. When completes, let nothing happen
        present(popVC, animated: true, completion: nil)
    }
}

extension MapVC: UIViewControllerPreviewingDelegate {
    //当开始按时周围的视图模糊显示的画面
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else {return nil}
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: popVCIdentifier) as? PopVC else {return nil}
        popVC.initView(withImage: imageArray[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame //sourceRect is the rect that stays sharp while the background turn blur
        return popVC
    }
    
    //当按重时弹出的界面，上面的函数在执行完后会将返回结果传入此函数，所以在下面的show()中可以直接写形参名
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)//present a VC in primary context
    }
}














