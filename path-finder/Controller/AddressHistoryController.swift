//
//  AddressHistoryController.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 19.05.2022.
//

import UIKit
import CoreData

class AddressHistoryController: UIViewController {

    @IBOutlet weak var tvRouteHistory: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                print(data.value(forKey: "destination_description") as! String)
            }
        } catch {
            print("Failed")
        }
    }
    
    
}
