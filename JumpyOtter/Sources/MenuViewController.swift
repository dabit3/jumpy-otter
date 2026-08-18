import UIKit

/// In-game menu with Settings and Profile pages. Everything is local
/// (backed by AppSettings / UserDefaults).
final class MenuViewController: UIViewController {

    private enum Page { case root, settings, profile }

    private let card = UIView()
    private let titleLabel = UILabel()
    private let contentStack = UIStackView()
    private let backButton = UIButton(type: .system)

    private var page: Page = .root

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.55)

        card.backgroundColor = UIColor(red: 0.13, green: 0.13, blue: 0.16, alpha: 0.96)
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 30, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)

        backButton.setTitle("BACK", for: .normal)
        styleButton(backButton)
        backButton.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(backButton)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 300),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            backButton.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 24),
            backButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            backButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            backButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(onBackgroundTap(_:)))
        view.addGestureRecognizer(tap)

        show(.root)
    }

    // MARK: - Pages

    private func show(_ newPage: Page) {
        page = newPage
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        view.endEditing(true)
        switch page {
        case .root:
            titleLabel.text = "MENU"
            backButton.setTitle("CLOSE", for: .normal)
            contentStack.addArrangedSubview(menuButton("SETTINGS", action: #selector(onSettings)))
            contentStack.addArrangedSubview(menuButton("PROFILE", action: #selector(onProfile)))
        case .settings:
            titleLabel.text = "SETTINGS"
            backButton.setTitle("BACK", for: .normal)
            buildSettingsPage()
        case .profile:
            titleLabel.text = "PROFILE"
            backButton.setTitle("BACK", for: .normal)
            buildProfilePage()
        }
    }

    private func buildSettingsPage() {
        let settings = AppSettings.shared

        let soundSwitch = UISwitch()
        soundSwitch.isOn = settings.soundEnabled
        soundSwitch.onTintColor = Palette.accentGold
        soundSwitch.addTarget(self, action: #selector(onSoundToggle(_:)), for: .valueChanged)
        contentStack.addArrangedSubview(labeledRow("SOUND", control: soundSwitch))

        let volumeSlider = UISlider()
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = settings.volume
        volumeSlider.tintColor = Palette.accentGold
        volumeSlider.addTarget(self, action: #selector(onVolumeChange(_:)), for: .valueChanged)
        contentStack.addArrangedSubview(rowLabel("VOLUME"))
        contentStack.addArrangedSubview(volumeSlider)
    }

    private func buildProfilePage() {
        let settings = AppSettings.shared

        contentStack.addArrangedSubview(rowLabel("USERNAME"))

        let field = UITextField()
        field.text = settings.username
        field.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        field.textColor = .white
        field.backgroundColor = UIColor(white: 1, alpha: 0.12)
        field.layer.cornerRadius = 10
        field.autocorrectionType = .no
        field.autocapitalizationType = .allCharacters
        field.returnKeyType = .done
        field.setLeftPaddingPoints(12)
        field.delegate = self
        field.addTarget(self, action: #selector(onUsernameChange(_:)), for: .editingChanged)
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(field)

        contentStack.addArrangedSubview(statRow("TOP SCORE", value: "\(settings.bestScore)"))
        contentStack.addArrangedSubview(statRow("CREATINE", value: "\(settings.totalCreatine)"))
    }

    // MARK: - UI helpers

    private func styleButton(_ button: UIButton) {
        button.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .heavy)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 1, alpha: 0.12)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func menuButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        styleButton(button)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func rowLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .heavy)
        label.textColor = .white
        return label
    }

    private func labeledRow(_ text: String, control: UIView) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [rowLabel(text), control])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        return row
    }

    private func statRow(_ text: String, value: String) -> UIStackView {
        let valueLabel = rowLabel(value)
        valueLabel.textColor = Palette.accentGold
        return labeledRow(text, control: valueLabel)
    }

    // MARK: - Actions

    @objc private func onSettings() { show(.settings) }
    @objc private func onProfile() { show(.profile) }

    @objc private func onBack() {
        switch page {
        case .root: dismiss(animated: true)
        case .settings, .profile: show(.root)
        }
    }

    @objc private func onBackgroundTap(_ g: UITapGestureRecognizer) {
        let point = g.location(in: view)
        if !card.frame.contains(point) {
            view.endEditing(true)
            if page == .root { dismiss(animated: true) }
        }
    }

    @objc private func onSoundToggle(_ s: UISwitch) {
        AppSettings.shared.soundEnabled = s.isOn
        if s.isOn { SoundManager.shared.play("coin", volume: 0.9) }
    }

    @objc private func onVolumeChange(_ s: UISlider) {
        AppSettings.shared.volume = s.value
    }

    @objc private func onUsernameChange(_ field: UITextField) {
        AppSettings.shared.username = field.text ?? ""
    }
}

extension MenuViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftViewMode = .always
    }
}
