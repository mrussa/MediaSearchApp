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
        imageView = UIImageView(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: view.bounds.height / 2))
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        view.addSubview(imageView)
        
        // UILabel для описания
        descriptionLabel = UILabel(frame: CGRect(x: 20, y: imageView.frame.maxY + 20, width: view.bounds.width - 40, height: 100))
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.isHidden = true
        view.addSubview(descriptionLabel)
        
        // UILabel для автора
        authorLabel = UILabel(frame: CGRect(x: 20, y: descriptionLabel.frame.maxY + 10, width: view.bounds.width - 40, height: 30))
        authorLabel.font = UIFont.boldSystemFont(ofSize: 16)
        authorLabel.isHidden = true
        view.addSubview(authorLabel)
        
        // Кнопка сохранения изображения
        saveButton = UIButton(type: .system)
        saveButton.setTitle("Сохранить изображение", for: .normal)
        saveButton.addTarget(self, action: #selector(saveImageToGallery), for: .touchUpInside)
        saveButton.frame = CGRect(x: 20, y: view.bounds.height - 80, width: view.bounds.width - 40, height: 50)
        saveButton.isHidden = true
        view.addSubview(saveButton)
        
        // Кнопка для поделиться
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareImage))
        navigationItem.rightBarButtonItem = shareButton
    }
    
    private func setupActivityIndicator() {
        // Индикатор активности для состояния загрузки
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    private func setupErrorLabel() {
        // UILabel для отображения ошибок
        errorLabel = UILabel(frame: CGRect(x: 20, y: view.center.y - 20, width: view.bounds.width - 40, height: 40))
        errorLabel.textColor = .red
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 18)
        errorLabel.isHidden = true
        view.addSubview(errorLabel)
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
