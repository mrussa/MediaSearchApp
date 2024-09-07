import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var searchBar: UISearchBar!
    var collectionView: UICollectionView!
    var searchHistory: [String] = []
    var searchResults: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Загрузка истории поиска
        loadSearchHistory()
        
        // Создание UISearchBar
        searchBar = UISearchBar()
        searchBar.placeholder = "Введите запрос для поиска"
        searchBar.delegate = self
        navigationItem.titleView = searchBar
        
        // Настройка макета UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: (view.frame.size.width / 2) - 15, height: 200)
        
        // Создание UICollectionView
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.backgroundColor = .white
        
        // Добавление UICollectionView на экран
        view.addSubview(collectionView)
    }
    
    // Загрузка истории поиска из UserDefaults
    func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: "searchHistory") ?? []
    }
    
    // Сохранение истории поиска в UserDefaults
    func saveSearchHistory(query: String) {
        if !searchHistory.contains(query) {
            searchHistory.insert(query, at: 0)
            if searchHistory.count > 5 {
                searchHistory.removeLast()
            }
            UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
        }
    }
    
    // UISearchBarDelegate: Начало поиска
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchBar.resignFirstResponder()
        
        // Сохранение истории поиска
        saveSearchHistory(query: query)
        
        // Отправка запроса на Unsplash API
        let apiClient = UnsplashAPIClient()
        apiClient.searchPhotos(query: query) { [weak self] result in
            switch result {
            case .success(let photos):
                self?.searchResults = photos
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            case .failure(let error):
                print("Ошибка: \(error)")
            }
        }
    }
    
    // UICollectionViewDataSource: Количество элементов
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    // UICollectionViewDataSource: Создание ячейки
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photo = searchResults[indexPath.item]
        cell.configure(with: photo)
        return cell
    }
}
