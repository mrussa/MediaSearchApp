import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate {

    private var searchBar: UISearchBar!
    private var historyTableView: UITableView!
    private var collectionView: UICollectionView!
    
    private var searchHistory: [String] = []
    private var searchResults: [Photo] = []
    private var apiClient = UnsplashAPIClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSearchHistory()
    }

    private func setupUI() {
        // Настройка UISearchBar
        searchBar = UISearchBar()
        searchBar.delegate = self
        navigationItem.titleView = searchBar

        // Настройка UITableView для истории запросов
        historyTableView = UITableView()
        historyTableView.frame = CGRect(x: 0, y: 100, width: view.frame.width, height: 200)
        historyTableView.dataSource = self
        historyTableView.delegate = self
        historyTableView.isHidden = true
        view.addSubview(historyTableView)

        // Настройка UICollectionView для результатов поиска
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        view.addSubview(collectionView)
    }
    
    // Сохранение истории поиска в UserDefaults
    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
    }

    // Загрузка истории поиска из UserDefaults
    private func loadSearchHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: "searchHistory") as? [String] {
            searchHistory = savedHistory
        }
        historyTableView.reloadData()
    }
    
    // UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchHistory.insert(query, at: 0)
        searchHistory = Array(Set(searchHistory)).prefix(5).map { $0 }
        saveSearchHistory()
        searchBar.resignFirstResponder()
        search(searchQuery: query)
    }
    
    private func search(searchQuery: String) {
        apiClient.searchPhotos(query: searchQuery) { result in
            switch result {
            case .success(let photos):
                self.searchResults = photos
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "HistoryCell")
        cell.textLabel?.text = searchHistory[indexPath.row]
        return cell
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let query = searchHistory[indexPath.row]
        searchBar.text = query
        search(searchQuery: query)
    }

    // UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return searchResults.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
            let photo = searchResults[indexPath.item]
            cell.configure(with: photo)
            return cell
        }
        
        // Новый метод для обработки нажатия на ячейку
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let selectedPhoto = searchResults[indexPath.item]
            
            // Создаем экземпляр PhotoDetailViewController
            let detailVC = PhotoDetailViewController()
            
            // Передаем фотографию в PhotoDetailViewController
            detailVC.photo = selectedPhoto
            
            // Переход на новый экран
            navigationController?.pushViewController(detailVC, animated: true)
        }
}

// UICollectionViewDelegateFlowLayout
extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 30) / 2
        return CGSize(width: width, height: width)
    }
}
