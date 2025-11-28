//
//  SoundService.swift
//  PasteMine
//
//  Created for sound effects support
//

import AVFoundation
import AppKit

class SoundService {
    static let shared = SoundService()

    private var audioPlayers: [AVAudioPlayer] = []

    private init() {}

    /// 播放复制音效
    func playCopySound() {
        let settings = AppSettings.load()
        guard settings.soundEnabled else { return }
        playSound(named: "3.wav")  // 水笔复制音效
    }

    /// 播放粘贴音效
    func playPasteSound() {
        let settings = AppSettings.load()
        guard settings.soundEnabled else { return }
        playSound(named: "4.wav")  // 水笔粘贴音效
    }

    /// 播放指定音效文件
    private func playSound(named filename: String) {
        // 从 Resources 目录加载音频文件
        guard let soundURL = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".wav", with: ""),
                                              withExtension: "wav") else {
            print("❌ 找不到音效文件: \(filename)")
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer.prepareToPlay()
            audioPlayer.play()

            // 保存引用，防止播放器被释放
            audioPlayers.append(audioPlayer)

            // 播放完成后移除引用
            DispatchQueue.main.asyncAfter(deadline: .now() + audioPlayer.duration + 0.1) { [weak self] in
                self?.audioPlayers.removeAll { $0 == audioPlayer }
            }

            print("🔊 播放音效: \(filename)")
        } catch {
            print("❌ 播放音效失败: \(error)")
        }
    }
}
