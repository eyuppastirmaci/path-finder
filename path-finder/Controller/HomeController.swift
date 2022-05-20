//
//  HomeController.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 18.05.2022.
//

import UIKit
import AVFoundation
import CoreLocation
import GoogleMaps
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
    
    var destLat: Double = 0.0
    var destLng: Double = 0.0

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
        btnSaveDestination.isEnabled = false
        txtDestinationDescription.isEnabled = false
        
        
    
        scanQRCode()
    }
    
    @objc func addTapped() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        
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
            self.showAlert(title: "Destination Not Saved", message: "You must first enter a destination description.")
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "DestinationEntity", in: context)
        let newDestination = NSManagedObject(entity: entity!, insertInto: context)
        
        
        newDestination.setValue(UUID(uuidString: UUID().uuidString), forKey: "id")
        newDestination.setValue(txtDestinationDescription.text, forKey: "destination_description")
        
        print("==================")
        print(destLat)
        print(destLng)
        print("==================")
        
        newDestination.setValue(destLat, forKey: "latitude")
        newDestination.setValue(destLng, forKey: "longitude")
        
        do {
          try context.save()
            self.showAlert(title: "Route Bookmarked", message: "\(txtDestinationDescription.text ?? "") successfully bookmarked!")
            txtDestinationDescription.text = ""
            txtDestinationDescription.isEnabled = false
            btnSaveDestination.isEnabled = false
         } catch {
          print("Error saving")
        }
    }
    
    @IBAction func cancelFindRoute(_ sender: Any) {
        captureSession.stopRunning()
        cameraView.layer.sublayers?.removeLast()
        dismiss(animated: true)
        btnCancelFindRoute.isHidden = true
        cameraView.isHidden = true
        navigationItem.leftBarButtonItem?.isEnabled = true
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
        
        navigationItem.leftBarButtonItem?.isEnabled = true
    }

    func found(code: String) {
        let dest : Array = code.components(separatedBy: " ")
        destLat = Double(dest[0]) ?? -91.0
        destLng = Double(dest[1]) ?? -181.0
         
        if (destLat < -90 || destLng < -180 || destLat > 90 || destLng > 90) {
            hideQRScanner()
            
            self.showAlert(title: "Cannot found address", message: "Unvalid coordinates in the QR code.")
        } else {
            hideQRScanner()
            Map.drawRoute(destinationLatitude: destLat, destinationLongitude: destLng, mapView: self.mapView)
        }
    }
    
    func hideQRScanner() {
        txtDestinationDescription.isEnabled = true
        btnSaveDestination.isEnabled = true
        btnCancelFindRoute.layer.isHidden = true
        cameraView.layer.isHidden = true
        dismiss(animated: true)
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
}
