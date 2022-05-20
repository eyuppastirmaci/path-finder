//
//  HomeController.swift
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
import CoreData

class HomeController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var txtDestinationDescription: UITextField!
    @IBOutlet weak var btnSaveDestination: UIButton!
    @IBOutlet weak var btnCancelFindRoute: UIButton!
    @IBOutlet weak var cameraView: UIView!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var sourceLat = 0.0
    var sourceLng = 0.0
    var destinationLat = 0.0
    var destinationLng = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Path Finder"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(historyTapped))
        
        cameraView.layer.zPosition = 1
        btnCancelFindRoute.layer.zPosition = 1
        mapView.layer.zPosition = 2
        
        cameraView.isHidden = true
        btnCancelFindRoute.isHidden = true
        
        getUserCoordinates()
        scanQRCode()
    }
    
    @objc func addTapped() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        cameraView.isHidden = false
        btnCancelFindRoute.isHidden = false
        
        cameraView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    @objc func historyTapped() {
        self.performSegue(withIdentifier: "goHistory", sender: nil)
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
    
    override var prefersStatusBarHidden: Bool { return true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBAction func addNewAddress(_ sender: Any) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        cameraView.layer.isHidden = false
        btnCancelFindRoute.layer.isHidden = false
        
        cameraView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    
    @IBAction func saveDestination(_ sender: Any) {
        if (txtDestinationDescription.text == nil || txtDestinationDescription.text == "") {
            let alert = UIAlertController(title: "Destination Not Saved", message: "You must first enter a destination description.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "DestinationEntity", in: context)
        let newDestination = NSManagedObject(entity: entity!, insertInto: context)
        
        newDestination.setValue(txtDestinationDescription.text, forKey: "destination_description")
        newDestination.setValue(destinationLat, forKey: "latitude")
        newDestination.setValue(destinationLng, forKey: "longitude")
        
        do {
          try context.save()
         } catch {
          print("Error saving")
        }
    }
    
    @IBAction func cancelFindRoute(_ sender: Any) {
        print("Cickled 1")
        
        captureSession.stopRunning()
        cameraView.layer.sublayers?.removeLast()
        dismiss(animated: true)
        
        btnCancelFindRoute.isHidden = true
        cameraView.isHidden = true
        print("Clicked 2")
    }
    
    
    func scanQRCode() {
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        let videoInput: AVCaptureDeviceInput
        let metadataOutput = AVCaptureMetadataOutput()
        
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

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
    }
    
    func getUserCoordinates() {
        let locManager = CLLocationManager()
        let authorizationStatus: CLAuthorizationStatus
        
        var currentLocation : CLLocation!
        
        locManager.requestWhenInUseAuthorization()
        
        if #available(iOS 14, *) {
            authorizationStatus = locManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        switch authorizationStatus {
            case .restricted, .denied:
                return
            default:
                 currentLocation = locManager.location
                 sourceLat = currentLocation.coordinate.latitude
                 sourceLng = currentLocation.coordinate.longitude
        }
    }
    
    func drawRoute(destinationLatitude: Double, destinationLongitude: Double) {
        hideQRScanner()
        
        destinationLat = destinationLatitude
        destinationLng = destinationLongitude
        
        let sourceLocation = "\(sourceLat),\(sourceLng)"
        let destinationLocation = "\(destinationLat),\(destinationLng)"
       
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(sourceLocation)&destination=\(destinationLocation)&mode=driving&key=\(ApplicationKeys.GOOGLE_API_KEY)"
        
        AF.request(url).responseJSON { (response) in
            guard let data = response.data else {
                print(response.error ?? "Google api response not success...")
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
        mapView.animate(to: camera)
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        cameraView.layer.sublayers?.removeLast()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }

    func found(code: String) {
        let dest : Array = code.components(separatedBy: " ")
        let destLat : Double = Double(dest[0]) ?? -91.0
        let destLng : Double = Double(dest[1]) ?? -181.0
         
        if (destLat < -90 || destLng < -180 || destLat > 90 || destLng > 90) {
            hideQRScanner()
            
            txtDestinationDescription.isUserInteractionEnabled = false
            btnSaveDestination.isUserInteractionEnabled = false
            
            let alert = UIAlertController(title: "Cannot found address", message: "Not valit coordinates in the QR code.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            drawRoute(destinationLatitude: destLat, destinationLongitude: destLng)
        }
    }
    
    func hideQRScanner() {
        txtDestinationDescription.isUserInteractionEnabled = true
        btnSaveDestination.isUserInteractionEnabled = true
        btnCancelFindRoute.layer.isHidden = true
        cameraView.layer.isHidden = true
        dismiss(animated: true)
    }
    
}
