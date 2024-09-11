import UIKit

// MARK: - PhotoDetailViewController

class PhotoDetailViewController: UIViewController {
    
    var imageView: UIImageView!
    var descriptionLabel: UILabel!
    var authorLabel: UILabel!
    var activityIndicator: UIActivityIndicatorView!
    var errorLabel: UILabel!
    var saveButton: UIButton!
    
    var photo: Photo?
    var loadedImage: UIImage?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupUI()
        setupActivityIndicator()
        setupErrorLabel()
        
        // MARK: - Data Loading
        if let photo = photo {
            showLoadingState()
            loadPhotoDetails(photo)
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // UIImageView для отображения изображения
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // UILabel для описания
        descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.isHidden = true
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // UILabel для автора
        authorLabel = UILabel()
        authorLabel.font = UIFont.boldSystemFont(ofSize: 16)
        authorLabel.isHidden = true
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(authorLabel)
        
        // Кнопка сохранения изображения
        saveButton = UIButton(type: .system)
        saveButton.setTitle("Сохранить изображение", for: .normal)
        saveButton.addTarget(self, action: #selector(saveImageToGallery), for: .touchUpInside)
        saveButton.isHidden = true
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        // Кнопка для поделиться
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareImage))
        navigationItem.rightBarButtonItem = shareButton
        
        setupConstraints()
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Constraints для imageView
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // Constraints для descriptionLabel
            descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Constraints для authorLabel
            authorLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            authorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            authorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Constraints для saveButton
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActivityIndicator() {
        // Индикатор активности для состояния загрузки
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Установка ограничений для индикатора активности
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupErrorLabel() {
        // UILabel для отображения ошибок
        errorLabel = UILabel()
        errorLabel.textColor = .red
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 18)
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        
        // Установка ограничений для errorLabel
        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading Methods
    private func loadPhotoDetails(_ photo: Photo) {
        descriptionLabel.text = photo.description ?? "Нет описания"
        authorLabel.text = "Автор: \(photo.author)"
        
        guard let url = URL(string: photo.urls.regular) else {
            showErrorState("Неверный URL изображения")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showErrorState(error.localizedDescription)
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.showErrorState("Не удалось загрузить изображение")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.loadedImage = image
                self.imageView.image = image
                self.showContentState()
            }
        }.resume()
    }
    
    // MARK: - UI State Management
    private func showLoadingState() {
        activityIndicator.startAnimating()
        imageView.isHidden = true
        descriptionLabel.isHidden = true
        authorLabel.isHidden = true
        saveButton.isHidden = true
        errorLabel.isHidden = true
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    private func showContentState() {
        activityIndicator.stopAnimating()
        imageView.isHidden = false
        descriptionLabel.isHidden = false
        authorLabel.isHidden = false
        saveButton.isHidden = false
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    private func showErrorState(_ message: String) {
        activityIndicator.stopAnimating()
        imageView.isHidden = true
        descriptionLabel.isHidden = true
        authorLabel.isHidden = true
        saveButton.isHidden = true
        errorLabel.text = message
        errorLabel.isHidden = false
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    // MARK: - Share Image Action
    @objc private func shareImage() {
        guard let imageToShare = loadedImage else { return }
        let activityVC = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    // MARK: - Save Image to Gallery
    @objc private func saveImageToGallery() {
        guard let imageToSave = loadedImage else {
            let alert = UIAlertController(title: "Ошибка", message: "Изображение не загружено", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            present(alert, animated: true)
            return
        }
        UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // MARK: - Image Saving Callback
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Успех", message: "Изображение сохранено в галерею", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            present(alert, animated: true)
        }
    }
}
