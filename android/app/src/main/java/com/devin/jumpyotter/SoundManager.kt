package com.devin.jumpyotter

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool

enum class Sfx { HOP, COIN, HIT, SPLASH, BUMP, TRAIN, BELL, EAGLE }

class SoundManager(context: Context) {
    private val pool = SoundPool.Builder()
        .setMaxStreams(6)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()

    private val ids: Map<Sfx, Int> = mapOf(
        Sfx.HOP to pool.load(context, R.raw.hop, 1),
        Sfx.COIN to pool.load(context, R.raw.coin, 1),
        Sfx.HIT to pool.load(context, R.raw.hit, 1),
        Sfx.SPLASH to pool.load(context, R.raw.splash, 1),
        Sfx.BUMP to pool.load(context, R.raw.bump, 1),
        Sfx.TRAIN to pool.load(context, R.raw.train, 1),
        Sfx.BELL to pool.load(context, R.raw.bell, 1),
        Sfx.EAGLE to pool.load(context, R.raw.eagle, 1),
    )

    fun play(sfx: Sfx, volume: Float = 1f) {
        val id = ids[sfx] ?: return
        pool.play(id, volume, volume, 1, 0, 1f)
    }

    fun release() = pool.release()
}
