import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegateFlowLayout {

    private var searchBar: UISearchBar!
    private var historyTableView: UITableView!
    private var collectionView: UICollectionView!
    
    private var searchHistory: [String] = []
    private var searchResults: [Photo] = []
    private var apiClient = UnsplashAPIClient()
    
    private var segmentedControl: UISegmentedControl!
    private var sortSegmentedControl: UISegmentedControl!
    private var currentSort: String = "relevant" // Сортировка по умолчанию
    
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var isLoadingMoreData = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSearchHistory()
    }

    private func setupUI() {
        // Настройка UISearchBar
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        // Настройка UISegmentedControl для выбора вида отображения
        segmentedControl = UISegmentedControl(items: ["2 плитки", "1 плитка"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(viewModeChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentTintColor = .white // Цвет выделенного сегмента
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        view.addSubview(segmentedControl)
        
        // Настройка UISegmentedControl для сортировки
        sortSegmentedControl = UISegmentedControl(items: ["Популярные", "Новые"])
        sortSegmentedControl.selectedSegmentIndex = 0
        sortSegmentedControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        sortSegmentedControl.selectedSegmentTintColor = .white // Цвет выделенного сегмента
        sortSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        view.addSubview(sortSegmentedControl)
        
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
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        // Добавляем констрейнты для размещения элементов друг под другом
        NSLayoutConstraint.activate([
            // Констрейнты для UISearchBar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Констрейнты для UISegmentedControl для выбора формата отображения
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Констрейнты для UISegmentedControl для сортировки
            sortSegmentedControl.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            sortSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Констрейнты для UICollectionView
            collectionView.topAnchor.constraint(equalTo: sortSegmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
        searchPhotos(query: query)
    }
    
    private func searchPhotos(query: String, page: Int = 1) {
        apiClient.searchPhotos(query: query, page: page, sort: currentSort) { result in
            switch result {
            case .success(let photos):
                if page == 1 {
                    self.searchResults = photos
                } else {
                    self.searchResults.append(contentsOf: photos)
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                self.isLoadingMoreData = false
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
        searchPhotos(query: query)
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

    // UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPhoto = searchResults[indexPath.item]
        let detailVC = PhotoDetailViewController()
        detailVC.photo = selectedPhoto
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if segmentedControl.selectedSegmentIndex == 0 {
            // Для двух плиток в ряд
            let width = (collectionView.bounds.width - 30) / 2
            return CGSize(width: width, height: width)
        } else {
            // Для одной плитки, во всю ширину экрана
            let width = collectionView.bounds.width - 20
            return CGSize(width: width, height: 400) // Можно подкорректировать высоту для удобства
        }
    }
    
    @objc func viewModeChanged() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    
    @objc func sortChanged() {
        currentSort = (sortSegmentedControl.selectedSegmentIndex == 0) ? "relevant" : "latest"
        searchBarSearchButtonClicked(searchBar) // Перезапуск поиска
    }

    // Добавление метода для загрузки дополнительных данных
    private func loadMorePhotos() {
        guard !isLoadingMoreData && currentPage < totalPages else { return }
        isLoadingMoreData = true
        currentPage += 1
        searchPhotos(query: searchBar.text ?? "", page: currentPage)
    }

    // UIScrollViewDelegate для отслеживания конца списка
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        if offsetY > contentHeight - height {
            loadMorePhotos()
        }
    }
}
