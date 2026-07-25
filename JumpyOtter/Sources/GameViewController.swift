import UIKit
import SceneKit

final class GameViewController: UIViewController, GameHUD {

    private var scnView: SCNView!
    private var game: GameController!

    // HUD
    private let scoreLabel = UILabel()
    private let creatineIcon = UIView()
    private let creatineLabel = UILabel()

    // Title overlay
    private let titleStack = UIStackView()
    private let logoLabel = UILabel()
    private let tapLabel = UILabel()

    // Game over overlay
    private let gameOverPanel = UIView()
    private let gameOverTitle = UILabel()
    private let finalScoreLabel = UILabel()
    private let bestLabel = UILabel()
    private let retryLabel = UILabel()
    private var canRetry = false

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

        setupHUD()
        setupOverlays()
        setupGestures()
    }

    // MARK: - HUD construction

    private func hudFont(_ size: CGFloat) -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: size, weight: .heavy)
    }

    private func styleOutlined(_ label: UILabel, size: CGFloat) {
        label.font = hudFont(size)
        label.textColor = .white
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowOpacity = 0.6
        label.layer.shadowRadius = 1
    }

    private func setupHUD() {
        styleOutlined(scoreLabel, size: 44)
        scoreLabel.text = "0"
        scoreLabel.accessibilityIdentifier = "score"
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)

        creatineIcon.backgroundColor = Palette.white
        creatineIcon.layer.cornerRadius = 4
        creatineIcon.layer.borderWidth = 2
        creatineIcon.layer.borderColor = Palette.black.cgColor
        creatineIcon.accessibilityIdentifier = "creatine"
        creatineIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(creatineIcon)

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

        NSLayoutConstraint.activate([
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

        styleOutlined(creatineLabel, size: 24)
        creatineLabel.text = "0"
        creatineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(creatineLabel)

        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            creatineLabel.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor),
            creatineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            creatineIcon.centerYAnchor.constraint(equalTo: creatineLabel.centerYAnchor),
            creatineIcon.trailingAnchor.constraint(equalTo: creatineLabel.leadingAnchor, constant: -8),
            creatineIcon.widthAnchor.constraint(equalToConstant: 20),
            creatineIcon.heightAnchor.constraint(equalToConstant: 26),
        ])
    }

    private func setupOverlays() {
        // Title
        logoLabel.text = "JUMPY\nOTTER"
        logoLabel.numberOfLines = 2
        logoLabel.textAlignment = .center
        styleOutlined(logoLabel, size: 64)
        logoLabel.layer.shadowOffset = CGSize(width: 0, height: 4)

        tapLabel.text = "TAP TO HOP"
        tapLabel.textAlignment = .center
        styleOutlined(tapLabel, size: 22)

        titleStack.axis = .vertical
        titleStack.spacing = 30
        titleStack.alignment = .center
        titleStack.addArrangedSubview(logoLabel)
        titleStack.addArrangedSubview(tapLabel)
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleStack)
        NSLayoutConstraint.activate([
            titleStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
        ])
        pulse(tapLabel)

        // Game over
        gameOverPanel.backgroundColor = UIColor(white: 0, alpha: 0.55)
        gameOverPanel.layer.cornerRadius = 18
        gameOverPanel.accessibilityIdentifier = "gameOverPanel"
        gameOverPanel.isHidden = true
        gameOverPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameOverPanel)

        gameOverTitle.text = "GAME OVER"
        styleOutlined(gameOverTitle, size: 40)
        styleOutlined(finalScoreLabel, size: 26)
        styleOutlined(bestLabel, size: 22)
        bestLabel.textColor = Palette.accentGold
        retryLabel.text = "TAP TO RETRY"
        styleOutlined(retryLabel, size: 22)

        let stack = UIStackView(arrangedSubviews: [gameOverTitle, finalScoreLabel, bestLabel, retryLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        gameOverPanel.addSubview(stack)

        NSLayoutConstraint.activate([
            gameOverPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameOverPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stack.topAnchor.constraint(equalTo: gameOverPanel.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: gameOverPanel.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: gameOverPanel.leadingAnchor, constant: 36),
            stack.trailingAnchor.constraint(equalTo: gameOverPanel.trailingAnchor, constant: -36),
        ])
        pulse(retryLabel)
    }

    private func pulse(_ v: UIView) {
        UIView.animate(withDuration: 0.7, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
            v.alpha = 0.35
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
            self.scoreLabel.text = "\(score)"
        }
    }

    func hudSetCreatine(_ creatine: Int) {
        DispatchQueue.main.async {
            self.creatineLabel.text = "\(creatine)"
        }
    }

    func hudStarted() {
        DispatchQueue.main.async {
            self.gameOverPanel.isHidden = true
            self.scoreLabel.text = "0"
            UIView.animate(withDuration: 0.25) {
                self.titleStack.alpha = 0
            } completion: { _ in
                self.titleStack.isHidden = true
            }
        }
    }

    func hudShowTitle() {
        DispatchQueue.main.async {
            self.gameOverPanel.isHidden = true
            self.scoreLabel.text = "0"
            self.titleStack.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.titleStack.alpha = 1
            }
        }
    }

    func hudGameOver(score: Int, best: Int, creatine: Int) {
        DispatchQueue.main.async {
            self.finalScoreLabel.text = "SCORE  \(score)"
            self.bestLabel.text = "TOP  \(best)"
            self.gameOverPanel.alpha = 0
            self.gameOverPanel.isHidden = false
            self.canRetry = false
            UIView.animate(withDuration: 0.3) {
                self.gameOverPanel.alpha = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.canRetry = true
            }
        }
    }

    private func hideGameOver() {
        gameOverPanel.isHidden = true
        scoreLabel.text = "0"
    }
}
