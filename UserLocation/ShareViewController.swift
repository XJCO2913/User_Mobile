import UIKit

class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var myview: UIView!
    struct User {
        let userId: String
        let username: String
        let avatarUrl: String
    }
    
    var users: [User] = []
    @IBOutlet weak var theTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myview.layer.cornerRadius = 20
        DispatchQueue.main.async {
            self.fetchUserList()
        }
        // 添加手势识别器
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
           view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    var username:[String] = []
    var imageurl:[String] = []
    func fetchUserList() {
        guard let url = URL(string: "http://43.136.232.116:5000/test/mock/shareList") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                // Handle error
                return
            }
            
            do {
                // Decode JSON data into UserListResponse
                let decoder = JSONDecoder()
                let userListResponse = try decoder.decode(UserListResponse.self, from: data)
                
                // Access user data from userListResponse.data array
                let users = userListResponse.Data
                
                // Clear existing data in arrays
                self?.username.removeAll()
                self?.imageurl.removeAll()
                
                // Append user data to arrays
                for user in users {
                    self?.username.append(user.username)
                    self?.imageurl.append(user.avatarUrl)
                }
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    // Reload table view data or update UI elements
                   
                    self?.theTable.reloadData()
                }
            } catch {
                // Handle JSON decoding error
                print("Error decoding JSON: \(error)")
            }
        }.resume()
    }


    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return username.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShareTableViewCell", for: indexPath) as! ShareTableViewCell
        
        cell.name.text = username[indexPath.row]
        
        if let url = URL(string: imageurl[indexPath.row]) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    // Resize the image to a smaller size
                    if let image = UIImage(data: data)?.resized(to: CGSize(width: 30, height: 30)) {
                        DispatchQueue.main.async {
                            cell.myimage.image = image
                        }
                    }
                }
            }
        }
        
        return cell
    }

}

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


struct UserListResponse: Codable {
    let status_code: Int
    let status_msg: String
    let Data: [User]
}

struct User: Codable {
    let userId: String
    let username: String
    let avatarUrl: String
}
