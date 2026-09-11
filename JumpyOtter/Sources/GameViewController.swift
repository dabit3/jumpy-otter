import UIKit
import SceneKit

/// Outlined arcade-style label: heavy rounded glyphs with an ink stroke and drop shadow.
final class ArcadeLabel: UILabel {
    var display: String = "" { didSet { rebuild() } }
    var fill: UIColor = .white { didSet { rebuild() } }
    var outline: UIColor = Palette.hudInk { didSet { rebuild() } }
    /// Stroke width as a percentage of the point size (NSAttributedString semantics).
    var outlineWidth: CGFloat = 6 { didSet { rebuild() } }
    var kern: CGFloat = 0 { didSet { rebuild() } }

    init(size: CGFloat, weight: UIFont.Weight = .black, rounded: Bool = true, monospacedDigits: Bool = false) {
        super.init(frame: .zero)
        font = ArcadeLabel.font(size: size, weight: weight, rounded: rounded, monospacedDigits: monospacedDigits)
        textAlignment = .center
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 0.55
        layer.shadowRadius = 2
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError("unsupported") }

    static func font(size: CGFloat, weight: UIFont.Weight, rounded: Bool, monospacedDigits: Bool) -> UIFont {
        var base = monospacedDigits
            ? UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
            : UIFont.systemFont(ofSize: size, weight: weight)
        if rounded, let desc = base.fontDescriptor.withDesign(.rounded) {
            base = UIFont(descriptor: desc, size: size)
        }
        return base
    }

    private func rebuild() {
        attributedText = NSAttributedString(string: display, attributes: [
            .font: font as UIFont,
            .foregroundColor: fill,
            .strokeColor: outline,
            .strokeWidth: -outlineWidth,
            .kern: kern,
        ])
    }
}

final class GameViewController: UIViewController, GameHUD {

    private var scnView: SCNView!
    private var game: GameController!

    // HUD chrome
    private let vignette = CAGradientLayer()
    private let flashView = UIView()

    // HUD
    private let scoreCard = UIView()
    private let scoreLabel = ArcadeLabel(size: 46, weight: .black, monospacedDigits: true)
    private let creatineCard = UIView()
    private let creatineIcon = UIView()
    private let creatineLabel = ArcadeLabel(size: 26, weight: .black, monospacedDigits: true)
    private let rivalStack = UIStackView()
    private var rivalChips: [Int: (chip: UIView, dot: UIView, label: ArcadeLabel)] = [:]
    private let bannerLabel = ArcadeLabel(size: 30)

    // Title overlay
    private let titleOverlay = UIView()
    private let logoTop = ArcadeLabel(size: 76)
    private let logoBottom = ArcadeLabel(size: 76)
    private let hiScoreLabel = ArcadeLabel(size: 18, monospacedDigits: true)
    private let tapLabel = ArcadeLabel(size: 26)
    private let creditsLabel = ArcadeLabel(size: 14, weight: .heavy)

    // Game over overlay
    private let gameOverPanel = UIView()
    private let gameOverTitle = ArcadeLabel(size: 44)
    private let rankPill = UIView()
    private let rankLabel = ArcadeLabel(size: 14, weight: .heavy)
    private let finalScoreLabel = ArcadeLabel(size: 60, monospacedDigits: true)
    private let bestLabel = ArcadeLabel(size: 20, monospacedDigits: true)
    private let retryLabel = ArcadeLabel(size: 22)
    private var canRetry = false
    private var countUpTimer: Timer?

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()

        game = GameController()
        game.hud = self

        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.scene = game.scene
        scnView.delegate = game
        scnView.rendersContinuously = true
        scnView.isPlaying = true
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60
        scnView.backgroundColor = Palette.sky
        scnView.showsStatistics = ProcessInfo.processInfo.arguments.contains("STATS")
        view.addSubview(scnView)

        setupChrome()
        setupHUD()
        setupOverlays()
        setupGestures()
        hudShowTitle(best: UserDefaults.standard.integer(forKey: "best"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        vignette.frame = view.bounds
    }

    // MARK: - Chrome (vignette + flash)

    private func setupChrome() {
        vignette.type = .radial
        vignette.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.38).cgColor]
        vignette.locations = [0, 0.55, 1]
        vignette.startPoint = CGPoint(x: 0.5, y: 0.5)
        vignette.endPoint = CGPoint(x: 1.05, y: 1.05)
        view.layer.addSublayer(vignette)

        flashView.isUserInteractionEnabled = false
        flashView.alpha = 0
        flashView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(flashView)
        NSLayoutConstraint.activate([
            flashView.topAnchor.constraint(equalTo: view.topAnchor),
            flashView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            flashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            flashView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func styleCard(_ card: UIView, radius: CGFloat = 16, border: CGFloat = 2, alpha: CGFloat = 0.78) {
        card.backgroundColor = Palette.hudNavy.withAlphaComponent(alpha)
        card.layer.cornerRadius = radius
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = border
        card.layer.borderColor = Palette.accentGold.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.35
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false
    }

    private func caption(_ text: String, color: UIColor = Palette.accentGold) -> ArcadeLabel {
        let l = ArcadeLabel(size: 12, weight: .heavy)
        l.kern = 2.5
        l.outlineWidth = 3
        l.fill = color
        l.display = text
        return l
    }

    // MARK: - HUD construction

    private func setupHUD() {
        // score card
        styleCard(scoreCard)
        view.addSubview(scoreCard)
        let scoreCaption = caption("SCORE")
        scoreLabel.display = "0"
        scoreLabel.accessibilityIdentifier = "score"
        scoreCard.addSubview(scoreCaption)
        scoreCard.addSubview(scoreLabel)
        NSLayoutConstraint.activate([
            scoreCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scoreCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scoreCard.widthAnchor.constraint(greaterThanOrEqualToConstant: 118),
            scoreCaption.topAnchor.constraint(equalTo: scoreCard.topAnchor, constant: 8),
            scoreCaption.centerXAnchor.constraint(equalTo: scoreCard.centerXAnchor),
            scoreLabel.topAnchor.constraint(equalTo: scoreCaption.bottomAnchor, constant: -2),
            scoreLabel.leadingAnchor.constraint(equalTo: scoreCard.leadingAnchor, constant: 16),
            scoreLabel.trailingAnchor.constraint(equalTo: scoreCard.trailingAnchor, constant: -16),
            scoreLabel.bottomAnchor.constraint(equalTo: scoreCard.bottomAnchor, constant: -6),
        ])

        // creatine card
        styleCard(creatineCard)
        view.addSubview(creatineCard)

        creatineIcon.backgroundColor = Palette.white
        creatineIcon.layer.cornerRadius = 4
        creatineIcon.layer.borderWidth = 2
        creatineIcon.layer.borderColor = Palette.black.cgColor
        creatineIcon.accessibilityIdentifier = "creatine"
        creatineIcon.translatesAutoresizingMaskIntoConstraints = false
        creatineCard.addSubview(creatineIcon)

        let lid = UIView()
        lid.backgroundColor = Palette.black
        lid.layer.cornerRadius = 2
        lid.translatesAutoresizingMaskIntoConstraints = false
        creatineIcon.addSubview(lid)

        let band = UIView()
        band.backgroundColor = Palette.cableRed
        band.translatesAutoresizingMaskIntoConstraints = false
        creatineIcon.addSubview(band)

        let mark = UILabel()
        mark.text = "C"
        mark.font = .systemFont(ofSize: 9, weight: .black)
        mark.textColor = .white
        mark.translatesAutoresizingMaskIntoConstraints = false
        band.addSubview(mark)

        creatineLabel.display = "0"
        creatineCard.addSubview(creatineLabel)

        NSLayoutConstraint.activate([
            creatineCard.topAnchor.constraint(equalTo: scoreCard.topAnchor),
            creatineCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            creatineCard.heightAnchor.constraint(equalToConstant: 48),
            creatineIcon.leadingAnchor.constraint(equalTo: creatineCard.leadingAnchor, constant: 12),
            creatineIcon.centerYAnchor.constraint(equalTo: creatineCard.centerYAnchor),
            creatineIcon.widthAnchor.constraint(equalToConstant: 20),
            creatineIcon.heightAnchor.constraint(equalToConstant: 26),
            creatineLabel.leadingAnchor.constraint(equalTo: creatineIcon.trailingAnchor, constant: 8),
            creatineLabel.trailingAnchor.constraint(equalTo: creatineCard.trailingAnchor, constant: -14),
            creatineLabel.centerYAnchor.constraint(equalTo: creatineCard.centerYAnchor),
            lid.topAnchor.constraint(equalTo: creatineIcon.topAnchor, constant: -1),
            lid.leadingAnchor.constraint(equalTo: creatineIcon.leadingAnchor, constant: -2),
            lid.trailingAnchor.constraint(equalTo: creatineIcon.trailingAnchor, constant: 2),
            lid.heightAnchor.constraint(equalToConstant: 6),
            band.leadingAnchor.constraint(equalTo: creatineIcon.leadingAnchor),
            band.trailingAnchor.constraint(equalTo: creatineIcon.trailingAnchor),
            band.centerYAnchor.constraint(equalTo: creatineIcon.centerYAnchor, constant: 2),
            band.heightAnchor.constraint(equalToConstant: 10),
            mark.centerXAnchor.constraint(equalTo: band.centerXAnchor),
            mark.centerYAnchor.constraint(equalTo: band.centerYAnchor),
        ])

        // rival chips (multiplayer)
        rivalStack.axis = .vertical
        rivalStack.spacing = 6
        rivalStack.alignment = .trailing
        rivalStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rivalStack)
        NSLayoutConstraint.activate([
            rivalStack.topAnchor.constraint(equalTo: creatineCard.bottomAnchor, constant: 8),
            rivalStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

        // event banner (joins, attacks, milestones, win)
        bannerLabel.alpha = 0
        bannerLabel.numberOfLines = 2
        bannerLabel.kern = 1
        view.addSubview(bannerLabel)
        NSLayoutConstraint.activate([
            bannerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            bannerLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            bannerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
        ])
    }

    private func setupOverlays() {
        // ---- Title (attract screen) ----
        titleOverlay.translatesAutoresizingMaskIntoConstraints = false
        titleOverlay.isUserInteractionEnabled = false
        view.addSubview(titleOverlay)
        NSLayoutConstraint.activate([
            titleOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            titleOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            titleOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let ribbon = caption("★  ARCADE EDITION  ★")
        ribbon.font = ArcadeLabel.font(size: 14, weight: .heavy, rounded: true, monospacedDigits: false)
        ribbon.kern = 3

        logoTop.display = "JUMPY"
        logoTop.fill = Palette.hudCream
        logoTop.outlineWidth = 7
        logoTop.kern = -1
        logoBottom.display = "OTTER"
        logoBottom.fill = Palette.hotOrange
        logoBottom.outlineWidth = 7
        logoBottom.kern = -1
        for l in [logoTop, logoBottom] {
            l.layer.shadowOffset = CGSize(width: 0, height: 6)
            l.layer.shadowOpacity = 0.5
            l.layer.shadowRadius = 3
        }
        let logo = UIStackView(arrangedSubviews: [logoTop, logoBottom])
        logo.axis = .vertical
        logo.spacing = -14
        logo.alignment = .center
        logo.transform = CGAffineTransform(rotationAngle: -0.06)

        hiScoreLabel.fill = Palette.accentGold
        hiScoreLabel.kern = 2
        hiScoreLabel.outlineWidth = 4

        let titleStack = UIStackView(arrangedSubviews: [ribbon, logo, hiScoreLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 18
        titleStack.alignment = .center
        titleStack.setCustomSpacing(26, after: logo)
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleOverlay.addSubview(titleStack)

        tapLabel.display = "TAP TO HOP"
        tapLabel.kern = 2
        let steer = caption("SWIPE TO STEER", color: Palette.hudSilver)
        let promptStack = UIStackView(arrangedSubviews: [tapLabel, steer])
        promptStack.axis = .vertical
        promptStack.spacing = 8
        promptStack.alignment = .center
        promptStack.translatesAutoresizingMaskIntoConstraints = false
        titleOverlay.addSubview(promptStack)

        creditsLabel.display = "1UP  ·  CREDITS 99  ·  PRESS TO START"
        creditsLabel.fill = Palette.hudSilver
        creditsLabel.kern = 2
        creditsLabel.outlineWidth = 3
        titleOverlay.addSubview(creditsLabel)

        NSLayoutConstraint.activate([
            titleStack.centerXAnchor.constraint(equalTo: titleOverlay.centerXAnchor),
            titleStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 104),
            promptStack.centerXAnchor.constraint(equalTo: titleOverlay.centerXAnchor),
            promptStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -92),
            creditsLabel.centerXAnchor.constraint(equalTo: titleOverlay.centerXAnchor),
            creditsLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22),
        ])
        pulse(tapLabel)
        bob(logo)

        // ---- Game over card ----
        styleCard(gameOverPanel, radius: 26, border: 3, alpha: 0.92)
        gameOverPanel.accessibilityIdentifier = "gameOverPanel"
        gameOverPanel.isHidden = true
        view.addSubview(gameOverPanel)

        gameOverTitle.display = "GAME OVER"
        gameOverTitle.fill = Palette.hotOrange
        gameOverTitle.outlineWidth = 7
        gameOverTitle.kern = 1

        rankPill.layer.cornerRadius = 12
        rankPill.layer.cornerCurve = .continuous
        rankPill.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.kern = 3
        rankLabel.outlineWidth = 0
        rankLabel.fill = Palette.hudInk
        rankLabel.layer.shadowOpacity = 0
        rankPill.addSubview(rankLabel)
        NSLayoutConstraint.activate([
            rankLabel.topAnchor.constraint(equalTo: rankPill.topAnchor, constant: 5),
            rankLabel.bottomAnchor.constraint(equalTo: rankPill.bottomAnchor, constant: -5),
            rankLabel.leadingAnchor.constraint(equalTo: rankPill.leadingAnchor, constant: 14),
            rankLabel.trailingAnchor.constraint(equalTo: rankPill.trailingAnchor, constant: -14),
        ])

        let scoreCaption = caption("SCORE", color: Palette.hudSilver)
        finalScoreLabel.display = "0"
        bestLabel.fill = Palette.accentGold
        bestLabel.kern = 2
        bestLabel.outlineWidth = 4

        let divider = UIView()
        divider.backgroundColor = Palette.accentGold.withAlphaComponent(0.5)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 2).isActive = true
        divider.widthAnchor.constraint(equalToConstant: 160).isActive = true

        retryLabel.display = "TAP TO RETRY"
        retryLabel.kern = 2

        let stack = UIStackView(arrangedSubviews: [gameOverTitle, rankPill, scoreCaption, finalScoreLabel, bestLabel, divider, retryLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        stack.setCustomSpacing(16, after: rankPill)
        stack.setCustomSpacing(-4, after: scoreCaption)
        stack.setCustomSpacing(16, after: bestLabel)
        stack.setCustomSpacing(16, after: divider)
        stack.translatesAutoresizingMaskIntoConstraints = false
        gameOverPanel.addSubview(stack)

        NSLayoutConstraint.activate([
            gameOverPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameOverPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            gameOverPanel.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
            stack.topAnchor.constraint(equalTo: gameOverPanel.topAnchor, constant: 26),
            stack.bottomAnchor.constraint(equalTo: gameOverPanel.bottomAnchor, constant: -26),
            stack.leadingAnchor.constraint(equalTo: gameOverPanel.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: gameOverPanel.trailingAnchor, constant: -32),
        ])
        pulse(retryLabel)
    }

    // MARK: - Animation helpers

    private func pulse(_ v: UIView) {
        UIView.animate(withDuration: 0.7, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
            v.alpha = 0.35
        }
    }

    private func bob(_ v: UIView) {
        let anim = CABasicAnimation(keyPath: "transform.translation.y")
        anim.fromValue = -6
        anim.toValue = 6
        anim.duration = 1.4
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        v.layer.add(anim, forKey: "bob")
    }

    private func pop(_ v: UIView, scale: CGFloat = 1.28, duration: TimeInterval = 0.32) {
        v.layer.removeAnimation(forKey: "pop")
        let anim = CAKeyframeAnimation(keyPath: "transform.scale")
        anim.values = [1, scale, 0.94, 1]
        anim.keyTimes = [0, 0.35, 0.7, 1]
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        v.layer.add(anim, forKey: "pop")
    }

    private func slamIn(_ v: UIView) {
        v.alpha = 0
        v.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.62, initialSpringVelocity: 0.8,
                       options: [.allowUserInteraction]) {
            v.alpha = 1
            v.transform = .identity
        }
    }

    // MARK: - Gestures

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        view.addGestureRecognizer(tap)
        for swipeDir: UISwipeGestureRecognizer.Direction in [.up, .down, .left, .right] {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
            swipe.direction = swipeDir
            view.addGestureRecognizer(swipe)
            tap.require(toFail: swipe)
        }
    }

    @objc private func onTap() {
        if game.state == .gameOver {
            guard canRetry else { return }
            hideGameOver()
            game.restart()
        } else {
            game.handleTap()
        }
    }

    @objc private func onSwipe(_ g: UISwipeGestureRecognizer) {
        // Swipes are in screen space; the camera looks diagonally so screen-up
        // maps to world forward, screen-right maps to Dir.right (world -X).
        switch g.direction {
        case .up: game.handleSwipe(.forward)
        case .down: game.handleSwipe(.back)
        case .left: game.handleSwipe(.left)
        case .right: game.handleSwipe(.right)
        default: break
        }
    }

    // MARK: - GameHUD (called from render thread)

    func hudSetScore(_ score: Int) {
        DispatchQueue.main.async {
            self.scoreLabel.display = "\(score)"
            self.pop(self.scoreLabel, scale: 1.22, duration: 0.26)
        }
    }

    func hudSetCreatine(_ creatine: Int) {
        DispatchQueue.main.async {
            let changed = self.creatineLabel.display != "\(creatine)"
            self.creatineLabel.display = "\(creatine)"
            if changed { self.pop(self.creatineCard, scale: 1.18) }
        }
    }

    func hudStarted() {
        DispatchQueue.main.async {
            self.gameOverPanel.isHidden = true
            self.scoreLabel.display = "0"
            UIView.animate(withDuration: 0.28) {
                self.titleOverlay.alpha = 0
                self.titleOverlay.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            } completion: { _ in
                self.titleOverlay.isHidden = true
                self.titleOverlay.transform = .identity
            }
        }
    }

    func hudShowTitle(best: Int) {
        DispatchQueue.main.async {
            self.gameOverPanel.isHidden = true
            self.scoreLabel.display = "0"
            self.hiScoreLabel.display = "HI-SCORE  \(best)"
            self.titleOverlay.isHidden = false
            self.titleOverlay.transform = .identity
            UIView.animate(withDuration: 0.3) {
                self.titleOverlay.alpha = 1
            }
        }
    }

    func hudGameOver(score: Int, best: Int, creatine: Int, newBest: Bool) {
        DispatchQueue.main.async {
            self.rankLabel.display = Rank.title(for: score)
            self.rankPill.backgroundColor = Rank.color(for: score)
            self.bestLabel.display = newBest && score > 0 ? "★  NEW RECORD!  ★" : "BEST  \(best)"
            self.bestLabel.layer.removeAllAnimations()
            self.bestLabel.alpha = 1
            if newBest && score > 0 { self.pulse(self.bestLabel) }
            self.gameOverPanel.isHidden = false
            self.canRetry = false
            self.slamIn(self.gameOverPanel)
            self.countUp(to: score)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.canRetry = true
            }
        }
    }

    func hudFlash(_ color: UIColor) {
        DispatchQueue.main.async {
            self.flashView.layer.removeAllAnimations()
            self.flashView.backgroundColor = color
            self.flashView.alpha = 1
            UIView.animate(withDuration: 0.4) {
                self.flashView.alpha = 0
            }
        }
    }

    private func countUp(to target: Int) {
        countUpTimer?.invalidate()
        finalScoreLabel.display = "0"
        guard target > 0 else { return }
        let steps = min(target, 24)
        var step = 0
        countUpTimer = Timer.scheduledTimer(withTimeInterval: 0.55 / Double(steps), repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            let value = step >= steps ? target : Int(Double(target) * Double(step) / Double(steps))
            self.finalScoreLabel.display = "\(value)"
            if step >= steps {
                timer.invalidate()
                self.pop(self.finalScoreLabel, scale: 1.2)
            }
        }
    }

    private func hideGameOver() {
        countUpTimer?.invalidate()
        gameOverPanel.isHidden = true
        scoreLabel.display = "0"
    }

    // MARK: - Multiplayer HUD

    func hudSetRivals(_ rivals: [RivalStatus]) {
        DispatchQueue.main.async {
            let ids = Set(rivals.map(\.id))
            for (id, entry) in self.rivalChips where !ids.contains(id) {
                entry.chip.removeFromSuperview()
                self.rivalChips.removeValue(forKey: id)
            }
            for rival in rivals {
                let entry: (chip: UIView, dot: UIView, label: ArcadeLabel)
                if let existing = self.rivalChips[rival.id] {
                    entry = existing
                } else {
                    entry = self.makeRivalChip(id: rival.id)
                    self.rivalChips[rival.id] = entry
                    self.rivalStack.addArrangedSubview(entry.chip)
                    self.pop(entry.chip)
                }
                entry.label.display = "P\(rival.id + 1)  \(rival.score)" + (rival.alive ? "" : "  OUT")
                entry.label.fill = rival.alive ? .white : Palette.hudSilver
                entry.dot.backgroundColor = rival.alive ? Palette.rivalColor(rival.id) : Palette.hudSilver
                entry.chip.alpha = rival.alive ? 1 : 0.55
            }
        }
    }

    private func makeRivalChip(id: Int) -> (chip: UIView, dot: UIView, label: ArcadeLabel) {
        let chip = UIView()
        styleCard(chip, radius: 12, border: 1.5, alpha: 0.7)
        chip.layer.borderColor = Palette.rivalColor(id).cgColor
        let dot = UIView()
        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false
        let label = ArcadeLabel(size: 16, weight: .heavy, monospacedDigits: true)
        label.outlineWidth = 3
        chip.addSubview(dot)
        chip.addSubview(label)
        NSLayoutConstraint.activate([
            chip.heightAnchor.constraint(equalToConstant: 30),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10),
            dot.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 10),
            dot.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 7),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
        ])
        return (chip, dot, label)
    }

    func hudBanner(_ text: String, color: UIColor) {
        DispatchQueue.main.async {
            self.bannerLabel.display = text
            self.bannerLabel.fill = color
            self.bannerLabel.layer.removeAllAnimations()
            self.bannerLabel.alpha = 1
            self.bannerLabel.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 1.2,
                           options: [.allowUserInteraction]) {
                self.bannerLabel.transform = .identity
            }
            UIView.animate(withDuration: 0.5, delay: 1.8, options: []) {
                self.bannerLabel.alpha = 0
            }
        }
    }
}
