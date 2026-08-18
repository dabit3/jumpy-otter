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
    private var volumeSlider: UISlider?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)

        card.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 0.97)
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(white: 1, alpha: 0.08).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)

        backButton.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(backButton)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 300),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
            backButton.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 20),
            backButton.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            backButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(onBackgroundTap(_:)))
        view.addGestureRecognizer(tap)

        show(.root)
    }

    // MARK: - Pages

    private func show(_ newPage: Page) {
        page = newPage
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        volumeSlider = nil
        view.endEditing(true)
        switch page {
        case .root:
            setTitle("MENU")
            setBackTitle("CLOSE")
            contentStack.addArrangedSubview(navRow("SETTINGS", icon: "gearshape.fill", action: #selector(onSettings)))
            contentStack.addArrangedSubview(separator())
            contentStack.addArrangedSubview(navRow("PROFILE", icon: "person.fill", action: #selector(onProfile)))
        case .settings:
            setTitle("SETTINGS")
            setBackTitle("BACK")
            buildSettingsPage()
        case .profile:
            setTitle("PROFILE")
            setBackTitle("BACK")
            buildProfilePage()
        }
    }

    private func buildSettingsPage() {
        let settings = AppSettings.shared

        let soundSwitch = UISwitch()
        soundSwitch.isOn = settings.soundEnabled
        soundSwitch.onTintColor = Palette.accentGold
        soundSwitch.addTarget(self, action: #selector(onSoundToggle(_:)), for: .valueChanged)
        contentStack.addArrangedSubview(controlRow("SOUND", icon: "speaker.wave.2.fill", control: soundSwitch))

        contentStack.addArrangedSubview(separator())

        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = settings.volume
        slider.minimumTrackTintColor = Palette.accentGold
        slider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.15)
        slider.isEnabled = settings.soundEnabled
        slider.alpha = settings.soundEnabled ? 1 : 0.35
        slider.addTarget(self, action: #selector(onVolumeChange(_:)), for: .valueChanged)
        volumeSlider = slider

        let volumeRow = UIStackView(arrangedSubviews: [rowLabel("VOLUME"), slider])
        volumeRow.axis = .vertical
        volumeRow.spacing = 14
        volumeRow.isLayoutMarginsRelativeArrangement = true
        volumeRow.layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        contentStack.addArrangedSubview(volumeRow)
    }

    private func buildProfilePage() {
        let settings = AppSettings.shared

        let field = UITextField()
        field.text = settings.username
        field.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .bold)
        field.textColor = .white
        field.tintColor = Palette.accentGold
        field.backgroundColor = UIColor(white: 1, alpha: 0.08)
        field.layer.cornerRadius = 12
        field.autocorrectionType = .no
        field.autocapitalizationType = .allCharacters
        field.returnKeyType = .done
        field.textAlignment = .center
        field.delegate = self
        field.addTarget(self, action: #selector(onUsernameChange(_:)), for: .editingChanged)
        field.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let nameStack = UIStackView(arrangedSubviews: [rowLabel("USERNAME"), field])
        nameStack.axis = .vertical
        nameStack.spacing = 10
        nameStack.isLayoutMarginsRelativeArrangement = true
        nameStack.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)
        contentStack.addArrangedSubview(nameStack)

        contentStack.addArrangedSubview(separator())
        contentStack.addArrangedSubview(statRow("TOP SCORE", value: "\(settings.bestScore)"))
        contentStack.addArrangedSubview(separator())
        contentStack.addArrangedSubview(statRow("CREATINE", value: "\(settings.totalCreatine)"))
    }

    // MARK: - UI helpers

    private func setTitle(_ text: String) {
        titleLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .heavy),
                .kern: 4,
                .foregroundColor: UIColor(white: 1, alpha: 0.55),
            ]
        )
    }

    private func setBackTitle(_ text: String) {
        backButton.setAttributedTitle(NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .heavy),
                .kern: 3,
                .foregroundColor: Palette.accentGold,
            ]
        ), for: .normal)
    }

    private func rowLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .bold),
                .kern: 1.5,
                .foregroundColor: UIColor.white,
            ]
        )
        return label
    }

    private func rowIcon(_ name: String) -> UIImageView {
        let icon = UIImageView(image: UIImage(
            systemName: name,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        ))
        icon.tintColor = UIColor(white: 1, alpha: 0.45)
        icon.contentMode = .center
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        return icon
    }

    private func separator() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor(white: 1, alpha: 0.08)
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    private func navRow(_ title: String, icon: String, action: Selector) -> UIControl {
        let row = UIControl()
        row.addTarget(self, action: action, for: .touchUpInside)
        row.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let chevron = UIImageView(image: UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        ))
        chevron.tintColor = UIColor(white: 1, alpha: 0.3)

        let stack = UIStackView(arrangedSubviews: [rowIcon(icon), rowLabel(title), UIView(), chevron])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            stack.topAnchor.constraint(equalTo: row.topAnchor),
            stack.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }

    private func controlRow(_ title: String, icon: String, control: UIView) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [rowIcon(icon), rowLabel(title), UIView(), control])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return row
    }

    private func statRow(_ title: String, value: String) -> UIStackView {
        let valueLabel = UILabel()
        valueLabel.attributedText = NSAttributedString(
            string: value,
            attributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .heavy),
                .kern: 1,
                .foregroundColor: Palette.accentGold,
            ]
        )
        let row = UIStackView(arrangedSubviews: [rowLabel(title), UIView(), valueLabel])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return row
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
        if let slider = volumeSlider {
            slider.isEnabled = s.isOn
            UIView.animate(withDuration: 0.2) { slider.alpha = s.isOn ? 1 : 0.35 }
        }
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
