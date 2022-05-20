//
//  AddressHistoryController.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 19.05.2022.
//

import UIKit
import CoreData
import AVFoundation
import GoogleMaps
import CoreLocation
import SwiftyJSON
import Alamofire

class AddressHistoryController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    @IBOutlet weak var tvRouteHistory: UITableView!
    @IBOutlet weak var mapView: GMSMapView!
    
    var destinationModels = [DestinationModel]()
    var sourceLat = 0.0
    var sourceLng = 0.0
    var destinationLat = 0.0
    var destinationLng = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tvRouteHistory.dataSource = self
        tvRouteHistory.delegate = self
        fetchDestinations()
    }
    
    func fetchDestinations() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DestinationEntity")
                
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                
                let id: UUID = data.value(forKey: "id") as! UUID
                print(id)
                let destinationDescription: String = data.value(forKey: "destination_description") as! String
                let latitude: Double = data.value(forKey: "latitude") as! Double
                let longitude: Double = data.value(forKey: "longitude") as! Double
                
                let currentDescriptionModel = DestinationModel(id: id, description: destinationDescription, latitude: latitude, longitude: longitude)
                
                destinationModels.append(currentDescriptionModel)
                
            }
        } catch {
            print("Failed")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return destinationModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = destinationModels[indexPath.row].description
        return cell
    }
    
   func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
       let selectedLat = destinationModels[indexPath.row].latitude
       let selectedLng = destinationModels[indexPath.row].longitude
       Map.drawRoute(destinationLatitude: selectedLat, destinationLongitude: selectedLng, mapView: self.mapView)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let selectedId = destinationModels[indexPath.row].id
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DestinationEntity")
            fetchRequest.predicate = NSPredicate(format: "id = %@", selectedId as CVarArg)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID {
                            if id == destinationModels[indexPath.row].id {
                                context.delete(result)
                                self.tvRouteHistory.reloadData()
                                
                                do {
                                    try context.save()
                                } catch {
                                    print("error")
                                }
                                break
                            }
                        }
                    }
                }
                
            } catch {
                print("error")
            }
            
            self.destinationModels.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
    }
    
    func removeCoreData() {
        guard let appDelegate =
          UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DestinationEntity") // Find this name in your .xcdatamodeld file
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(deleteRequest)
        } catch let error as NSError {
            // TODO: handle the error
            print(error.localizedDescription)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
}
