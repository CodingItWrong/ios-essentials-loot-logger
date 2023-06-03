//
//  ItemsViewController.swift
//  LootLogger
//
//  Created by Josh Justice on 5/12/23.
//

import UIKit

class ItemsViewController: UITableViewController {
    
    @IBOutlet var editButton: UIButton!
    
    var itemStore: ItemStore!
    var imageStore: ImageStore!
    
    var numItems: Int {
        return itemStore.allItems.count
    }
    var isEmpty: Bool {
        return numItems == 0
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 65
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(numItems, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell
        
        if isEmpty {
            cell.nameLabel.text = "No items!"
            cell.serialNumberLabel.text = ""
            cell.valueLabel.text = ""
        } else {
            let item = itemStore.allItems[indexPath.row]
            cell.nameLabel.text = "\(item.name)\(item.isFavorite ? " (favorite)" : "")"
            cell.serialNumberLabel.text = item.serialNumber
            cell.valueLabel.text = "$\(item.valueInDollars)"
        }
        
        return cell
    }
    
    @IBAction func addNewItem(_ sender: UIBarButtonItem) {
        let newItem = itemStore.createItem()
        
        if let index = itemStore.allItems.firstIndex(of: newItem) {
            let indexPath = IndexPath(row: index, section: 0)
            
            if numItems == 1 {
                tableView.reloadData() // refresh the "No items!" row
            } else {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            moveRowAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
        itemStore.moveItem(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) {
            [weak self] suggestedActions in
            
            var children: [UIMenuElement]
            
            if let self = self,
                  !self.isEmpty {
                let item = itemStore.allItems[indexPath.row]
                
                let favoriteAction = UIAction(title: item.isFavorite ? "Unfavorite" : "Favorite",
                                              image: UIImage(systemName: "heart")) {
                    [weak self] _ in
                    self?.toggleFavorite(forItemAt: indexPath)
                }
                
                let deleteAction = UIAction(title: "Delete",
                                            image: UIImage(systemName: "trash")) {
                    [weak self] _ in
                    self?.deleteItem(at: indexPath)
                }
                
                children = [favoriteAction, deleteAction]
            } else {
                children = []
            }
            
            return UIMenu(title: "", children: children)
        }
                                          
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteItem(at: indexPath)
        }
    }
    
    func toggleFavorite(forItemAt indexPath: IndexPath) {
        guard numItems > 0 else { return }
        
        let item = itemStore.allItems[indexPath.row]
        item.isFavorite = !item.isFavorite
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func deleteItem(at indexPath: IndexPath) {
        guard numItems > 0 else { return }
        
        let item = itemStore.allItems[indexPath.row]
        itemStore.removeItem(item)
        imageStore.deleteImage(forKey: item.itemKey)
        if isEmpty {
            tableView.reloadData() // refresh to get the "No items!" row
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showItem":
            if !isEmpty,
               let row = tableView.indexPathForSelectedRow?.row {
                let item = itemStore.allItems[row]
                let detailViewController = segue.destination as! DetailViewController
                detailViewController.item = item
                detailViewController.imageStore = imageStore
            }
        default:
            preconditionFailure("Unexpected segue identifier: \(String(describing: segue.identifier))")
        }
    }
    
}
