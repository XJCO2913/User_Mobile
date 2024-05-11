//
//  ViewController.swift
//  UserLocation
//
//  Created by student on 3/5/2024.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var startstopLabel: UILabel!
    
  
    @IBOutlet weak var totaldistanceLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    @IBOutlet weak var bottomView: UIView!
    // MARK: Map & Location related stuff
    
    @IBOutlet weak var myMap: MKMapView!
    
    var locationManager = CLLocationManager()
    
    var firstRun = true
    var startTrackingTheUser = false
    var userLocations: [CLLocation] = []
    var currentPolyline: MKPolyline?
    
    
    // MARK: View related Stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.layer.cornerRadius = 20
        tapCount = 0
        myMap.delegate = self
        
        // Make this view controller a delegate of the Location Managaer, so that it
        //is able to call functions provided in this view controller.
        locationManager.delegate = self
        //set the level of accuracy for the user's location.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        //Ask the location manager to request authorisation from the user. Note that this
        //only happens once if the user selects the "when in use" option. If the user
        //denies access, then your app will not be provided with details of the user's
        //location.
        locationManager.requestWhenInUseAuthorization()
        
        //Once the user's location is being provided then ask for udpates when the user
        //moves around.
        locationManager.startUpdatingLocation()
        
        //configure the map to show the user's location (with a blue dot).
        myMap.showsUserLocation = true
        startTrackingTheUser = false
        
    }
    

    func drawPolyline() {
        // 移除旧的 Polyline

        // 根据 userLocations 中的点创建一个 CLLocationCoordinate2D 数组
        let coordinates = userLocations.map { $0.coordinate }
        
        // 创建一个新的 Polyline
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        myMap.addOverlay(polyline)
        
        // 更新当前 Polyline 的引用
        currentPolyline = polyline
    }
    var lastLocation: CLLocation?

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let locationOfUser = userLocation.location // 获取 CLLocation

        guard let validLocation = locationOfUser else { return } // 确保 locationOfUser 不是 nil
        if startTrackingTheUser {
            myMap.setCenter(validLocation.coordinate, animated: true)
            
            if let lastLocation = lastLocation {
                let distance = validLocation.distance(from: lastLocation)
                totalDistance += distance
                // 实时更新界面上的总距离
                totaldistanceLabel.text = String(format: "%.2f m", totalDistance)
            }
            
            lastLocation = validLocation
            userLocations.append(validLocation) // 将 CLLocation 添加到 userLocations 数组
            drawPolyline()
        }
    }


  

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .green // 设置 Polyline 的颜色
            renderer.lineWidth = 5.0 // 设置 Polyline 的线宽
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationOfUser = locations.first else { return } // 使用 guard 语句确保有位置信息

        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude

        if firstRun {
            firstRun = false
            let latDelta: CLLocationDegrees = 0.001
            let lonDelta: CLLocationDegrees = 0.001
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let region = MKCoordinateRegion(center: locationOfUser.coordinate, span: span)
            self.myMap.setRegion(region, animated: true)

        }
        
        // 如果开始跟踪用户，每次位置更新时都打印当前的经纬度
        if startTrackingTheUser {
            myMap.setCenter(locationOfUser.coordinate, animated: true)
           // print("Current latitude: \(latitude), longitude: \(longitude)")
        }
    }
    
    @IBOutlet weak var startstopbutton: UIButton!
    var tapCount = 0
    var totalDistance: CLLocationDistance = 0.0

    var timer = Timer()
    var seconds = 0

    @IBAction func startstopTapped(_ sender: Any) {
        if tapCount % 2 == 0 {
            // Stop
            startstopLabel.text = "Stop"
            startstopbutton.setImage(UIImage(systemName: "pause"), for: .normal)
            self.startTrackingTheUser = true
            
            // Start timer
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        } else {
    
            // Stop timer
            timer.invalidate()
            // Start
            startstopLabel.text = "Start"
            self.startTrackingTheUser = false
            startstopbutton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            print("目前所有位置数据是",userLocations.description)
            
            // Share route data
            let receiverId = "c9d7b071-faf1-11ee-bc92-0242ac150007"
            var routeData: [[String]] = []
            for location in userLocations {
                let longitude = String(location.coordinate.longitude)
                let latitude = String(location.coordinate.latitude)
                routeData.append([longitude, latitude])
            }
            let postData: [String: Any] = [
                "receiverId": receiverId,
                "routeData": routeData
            ]
            
            guard let url = URL(string: "http://43.136.232.116:5000/test/notify/route") else {
                    print("Invalid URL")
                    return
                }
                
                // 创建一个 URLRequest 对象，并配置为发送 POST 请求
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                // 将要发送的数据编码为 JSON 格式
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: postData, options: .prettyPrinted)
                } catch {
                    print("Error encoding data: \(error)")
                    return
                }
                
                // 创建 URLSession 对象
                let session = URLSession.shared
                
                // 创建一个数据任务来发送请求
                let task = session.dataTask(with: request) { data, response, error in
                // 处理响应
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                    
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    return
                }
                    
                print("Status code: \(httpResponse.statusCode)")
                    
                if let data = data {
                    // 如果有响应数据，可以在这里对数据进行处理
                    if let responseData = String(data: data, encoding: .utf8) {
                        print("Response data: \(responseData)")
                    }
                }
            }
                
            // 启动任务
            task.resume()
            
            //call next view controller
            if let anotherViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShareViewController") as? ShareViewController{
                   
                   // 使用 present 方法呈现视图控制器
                   self.present(anotherViewController, animated: true, completion: nil)
               }
        }
        
        tapCount += 1
    }

    @objc func updateTimer() {
        seconds += 1
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = (seconds % 3600) % 60
        
        // Update label with formatted time
        speedLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    
    
    
}

