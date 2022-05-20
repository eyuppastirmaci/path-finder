//
//  AddressHistoryController.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 19.05.2022.
//

import UIKit
import CoreData

class AddressHistoryController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    @IBOutlet weak var tvRouteHistory: UITableView!
    @IBOutlet weak var mapView: UIView!
    
    var destinationModels = [DestinationModel]()
    
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
                let destinationDescription: String = data.value(forKey: "destination_description") as! String
                let latitude: Double = data.value(forKey: "latitude") as! Double
                let longitude: Double = data.value(forKey: "longitude") as! Double
                
                let currentDescriptionModel = DestinationModel(description: destinationDescription, latitude: latitude, longitude: longitude)
                
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
       
       print(selectedLat)
       print(selectedLng)
    }
    
    
}
