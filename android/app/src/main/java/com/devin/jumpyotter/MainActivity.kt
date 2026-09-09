package com.devin.jumpyotter

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.opengl.GLSurfaceView
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.abs

class MainActivity : Activity(), GameHUD {

    private lateinit var game: GameController
    private lateinit var glView: GLSurfaceView
    private lateinit var sound: SoundManager
    private lateinit var gestures: GestureDetector

    // HUD
    private lateinit var scoreLabel: TextView
    private lateinit var creatineLabel: TextView
    private lateinit var rivalStack: LinearLayout
    private val rivalLabels = HashMap<Int, TextView>()
    private lateinit var bannerLabel: TextView

    // overlays
    private lateinit var titleStack: LinearLayout
    private lateinit var gameOverPanel: LinearLayout
    private lateinit var finalScoreLabel: TextView
    private lateinit var bestLabel: TextView
    private var canRetry = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        sound = SoundManager(this)
        val autopilot = intent.getBooleanExtra("AUTOPILOT", false)
        val relay = intent.getStringExtra("RELAY_URL") ?: MultiplayerClient.DEFAULT_URL
        game = GameController(getSharedPreferences("jumpyotter", MODE_PRIVATE), sound, autopilot, relay)
        game.hud = this

        val root = FrameLayout(this)
        glView = GLSurfaceView(this).apply {
            setEGLContextClientVersion(2)
            setEGLConfigChooser(8, 8, 8, 8, 16, 0)
            setRenderer(object : GLSurfaceView.Renderer {
                override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) = game.onSurfaceCreated()
                override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) = game.onSurfaceChanged(width, height)
                override fun onDrawFrame(gl: GL10?) = game.onDrawFrame()
            })
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }
        root.addView(glView, FrameLayout.LayoutParams(MATCH, MATCH))
        setupHUD(root)
        setupOverlays(root)
        setContentView(root)
        setupGestures(root)
        hideSystemBars()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    private fun hideSystemBars() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let {
                it.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        }
    }

    override fun onResume() {
        super.onResume()
        glView.onResume()
    }

    override fun onPause() {
        glView.onPause()
        super.onPause()
    }

    override fun onDestroy() {
        game.destroy()
        sound.release()
        super.onDestroy()
    }

    // MARK: - HUD construction

    private fun dp(v: Float): Int = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, resources.displayMetrics).toInt()

    private fun outlined(sizeSp: Float, text: String = ""): TextView = TextView(this).apply {
        this.text = text
        textSize = sizeSp
        setTextColor(Color.WHITE)
        typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
        setShadowLayer(2f, 0f, 3f, Color.argb(160, 0, 0, 0))
        includeFontPadding = false
    }

    private fun setupHUD(root: FrameLayout) {
        scoreLabel = outlined(44f, "0").apply { contentDescription = "score" }
        root.addView(scoreLabel, FrameLayout.LayoutParams(WRAP, WRAP, Gravity.TOP or Gravity.START).apply {
            topMargin = dp(36f); leftMargin = dp(20f)
        })

        val creatineRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val icon = TextView(this).apply {
            text = "C"
            textSize = 11f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setBackgroundColor(Palette.cableRed.toArgb())
            contentDescription = "creatine"
        }
        creatineRow.addView(icon, LinearLayout.LayoutParams(dp(20f), dp(26f)).apply { rightMargin = dp(8f) })
        creatineLabel = outlined(24f, "0")
        creatineRow.addView(creatineLabel)
        root.addView(creatineRow, FrameLayout.LayoutParams(WRAP, WRAP, Gravity.TOP or Gravity.END).apply {
            topMargin = dp(44f); rightMargin = dp(20f)
        })

        rivalStack = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.END }
        root.addView(rivalStack, FrameLayout.LayoutParams(WRAP, WRAP, Gravity.TOP or Gravity.END).apply {
            topMargin = dp(84f); rightMargin = dp(20f)
        })

        bannerLabel = outlined(24f).apply { gravity = Gravity.CENTER; alpha = 0f }
        root.addView(bannerLabel, FrameLayout.LayoutParams(MATCH, WRAP, Gravity.TOP).apply { topMargin = dp(100f) })
    }

    private fun setupOverlays(root: FrameLayout) {
        titleStack = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER_HORIZONTAL }
        val logo = outlined(64f, "JUMPY\nOTTER").apply {
            gravity = Gravity.CENTER
            setShadowLayer(2f, 0f, 5f, Color.argb(160, 0, 0, 0))
        }
        val tap = outlined(22f, "TAP TO HOP").apply { gravity = Gravity.CENTER }
        titleStack.addView(logo)
        titleStack.addView(tap, LinearLayout.LayoutParams(WRAP, WRAP).apply { topMargin = dp(30f) })
        root.addView(titleStack, FrameLayout.LayoutParams(MATCH, WRAP, Gravity.TOP).apply { topMargin = dp(120f) })
        pulse(tap)

        gameOverPanel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setBackgroundColor(Color.argb(140, 0, 0, 0))
            setPadding(dp(36f), dp(28f), dp(36f), dp(28f))
            visibility = View.GONE
            contentDescription = "gameOverPanel"
        }
        val title = outlined(40f, "GAME OVER")
        finalScoreLabel = outlined(26f)
        bestLabel = outlined(22f).apply { setTextColor(Palette.accentGold.toArgb()) }
        val retry = outlined(22f, "TAP TO RETRY")
        for ((i, v) in listOf(title, finalScoreLabel, bestLabel, retry).withIndex()) {
            gameOverPanel.addView(v, LinearLayout.LayoutParams(WRAP, WRAP).apply { if (i > 0) topMargin = dp(16f) })
        }
        root.addView(gameOverPanel, FrameLayout.LayoutParams(WRAP, WRAP, Gravity.CENTER).apply { bottomMargin = dp(80f) })
        pulse(retry)
    }

    private fun pulse(v: View) {
        v.animate().alpha(0.35f).setDuration(700).withEndAction {
            v.animate().alpha(1f).setDuration(700).withEndAction { pulse(v) }.start()
        }.start()
    }

    // MARK: - Gestures

    private fun setupGestures(root: View) {
        gestures = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onDown(e: MotionEvent): Boolean = true

            override fun onSingleTapUp(e: MotionEvent): Boolean {
                onTap()
                return true
            }

            override fun onFling(e1: MotionEvent?, e2: MotionEvent, vx: Float, vy: Float): Boolean {
                if (e1 == null) return false
                val dx = e2.x - e1.x
                val dy = e2.y - e1.y
                if (abs(dx) < dp(24f) && abs(dy) < dp(24f)) return false
                // Screen-up maps to world forward; screen-right maps to Dir.RIGHT (world -X).
                if (abs(dx) > abs(dy)) {
                    game.handleSwipe(if (dx > 0) Dir.RIGHT else Dir.LEFT)
                } else {
                    game.handleSwipe(if (dy < 0) Dir.FORWARD else Dir.BACK)
                }
                return true
            }
        })
        root.setOnTouchListener { _, event -> gestures.onTouchEvent(event); true }
    }

    private fun onTap() {
        if (game.state == GameController.State.GAME_OVER) {
            if (!canRetry) return
            gameOverPanel.visibility = View.GONE
            scoreLabel.text = "0"
            game.restart()
        } else {
            game.handleTap()
        }
    }

    // MARK: - GameHUD (called from the GL thread)

    override fun hudSetScore(score: Int) {
        runOnUiThread { scoreLabel.text = score.toString() }
    }

    override fun hudSetCreatine(creatine: Int) {
        runOnUiThread { creatineLabel.text = creatine.toString() }
    }

    override fun hudStarted() {
        runOnUiThread {
            gameOverPanel.visibility = View.GONE
            scoreLabel.text = "0"
            titleStack.animate().cancel()
            titleStack.animate().alpha(0f).setDuration(250).withEndAction {
                if (game.state != GameController.State.TITLE) titleStack.visibility = View.GONE
            }.start()
        }
    }

    override fun hudShowTitle() {
        runOnUiThread {
            if (game.state != GameController.State.TITLE) return@runOnUiThread
            gameOverPanel.visibility = View.GONE
            scoreLabel.text = "0"
            titleStack.animate().cancel()
            titleStack.visibility = View.VISIBLE
            titleStack.animate().alpha(1f).setDuration(250).start()
        }
    }

    override fun hudGameOver(score: Int, best: Int, creatine: Int) {
        runOnUiThread {
            finalScoreLabel.text = "SCORE  $score"
            bestLabel.text = "TOP  $best"
            titleStack.animate().cancel()
            titleStack.visibility = View.GONE
            gameOverPanel.alpha = 0f
            gameOverPanel.visibility = View.VISIBLE
            canRetry = false
            gameOverPanel.animate().alpha(1f).setDuration(300).start()
            gameOverPanel.postDelayed({ canRetry = true }, 500)
        }
    }

    override fun hudSetRivals(rivals: List<RivalStatus>) {
        runOnUiThread {
            val ids = rivals.map { it.id }.toSet()
            for ((id, label) in rivalLabels.toMap()) {
                if (id !in ids) {
                    rivalStack.removeView(label)
                    rivalLabels.remove(id)
                }
            }
            for (rival in rivals) {
                val label = rivalLabels.getOrPut(rival.id) {
                    outlined(18f).also { rivalStack.addView(it, LinearLayout.LayoutParams(WRAP, WRAP).apply { topMargin = dp(4f) }) }
                }
                label.setTextColor(Palette.rivalColor(rival.id).toArgb())
                label.text = "P${rival.id + 1}  ${rival.score}" + if (rival.alive) "" else "  ✕"
                label.alpha = if (rival.alive) 1f else 0.45f
            }
        }
    }

    override fun hudBanner(text: String, color: Rgb) {
        runOnUiThread {
            bannerLabel.text = text
            bannerLabel.setTextColor(color.toArgb())
            bannerLabel.animate().cancel()
            bannerLabel.alpha = 1f
            bannerLabel.animate().alpha(0f).setStartDelay(1800).setDuration(500).start()
        }
    }

    private companion object {
        const val MATCH = FrameLayout.LayoutParams.MATCH_PARENT
        const val WRAP = FrameLayout.LayoutParams.WRAP_CONTENT
    }
}
