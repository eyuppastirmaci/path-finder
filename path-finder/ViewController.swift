//
//  ViewController.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 18.05.2022.
//

import UIKit
import AVFoundation
import GoogleMaps
import CoreLocation
import SwiftyJSON
import Alamofire

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var readedAddress: String = ""
    
    var sourceLat = 0.0
    var sourceLng = 0.0
    var destinationLat = 0.0
    var destinationLng = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUserCoordinates()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
    }
    
    @IBAction func newAddress(_ sender: Any) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
    
    @IBAction func addressHistory(_ sender: Any) {
    
    }
    
    func getUserCoordinates() {
        
        var locManager = CLLocationManager()
        locManager.requestWhenInUseAuthorization()
        
        var currentLocation : CLLocation!
        
        if
           CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
           CLLocationManager.authorizationStatus() ==  .authorizedAlways {
            
            currentLocation = locManager.location
            
            sourceLat = currentLocation.coordinate.latitude
            sourceLng = currentLocation.coordinate.longitude
        
        } else {
            return
        }
    }
    
    func drawRoute(destinationLatitude: Double, destinationLongitude: Double) {
        
        destinationLat = destinationLatitude
        destinationLng = destinationLongitude
        
        let sourceLocation = "\(sourceLat),\(sourceLng)"
        let destinationLocation = "\(destinationLat),\(destinationLng)"
       
        var url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(sourceLocation)&destination=\(destinationLocation)&mode=driving&key=\(ApplicationKeys.GOOGLE_API_KEY)"
        
        
        AF.request(url).responseJSON { (response) in
            
            guard let data = response.data else {
                print(response.error)
                return
            }
            
            do {
                 
                let jsonData = try JSON(data: data)
                let routes = jsonData["routes"].arrayValue
                
                for route in routes {
                    
                    let overview_polyline = route["overview_polyline"].dictionary
                    let points = overview_polyline?["points"]?.string
                    let path = GMSPath.init(fromEncodedPath: points ?? "")
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeColor = .blue
                    polyline.strokeWidth = 5
                    polyline.map = self.mapView
                }
                
            } catch let error {
                print("Harita Çizdirilemedi...")
                print(error.localizedDescription)
            }
        }
        
        let sourceMarker = GMSMarker()
        sourceMarker.position = CLLocationCoordinate2D(latitude: sourceLat, longitude: sourceLng)
        sourceMarker.title = "Current Location"
        sourceMarker.snippet = "..."
        sourceMarker.map = self.mapView
        
        let destinationMarker = GMSMarker()
        destinationMarker.position = CLLocationCoordinate2D(latitude: destinationLat, longitude: destinationLng)
        destinationMarker.title = "Target Location"
        destinationMarker.snippet = "..."
        destinationMarker.map = self.mapView
        
        let camera = GMSCameraPosition(target: sourceMarker.position, zoom: 15)
        
        mapView.animate(to: camera)    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        view.layer.sublayers?.removeLast()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

            
        dismiss(animated: true)
    }

    func found(code: String) {
        readedAddress = code
        
        let dest : Array = readedAddress.components(separatedBy: " ")
        let destLat : Double = Double(dest[0]) ?? 0.0
        let destLng : Double = Double(dest[1]) ?? 0.0
        
        drawRoute(destinationLatitude: destLat, destinationLongitude: destLng)
        
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}

