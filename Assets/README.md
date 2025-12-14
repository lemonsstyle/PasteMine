# Assets

This directory contains additional sound assets for the PasteMine application.

## Sounds

The `Sounds/` directory contains 6 WAV audio files (1.wav - 6.wav) that can be used as alternative sound effects for copy/paste actions.

**Note**: The main application currently uses `3.wav` and `4.wav` (located in `PasteMine/PasteMine/Resources/Sounds/`). The files in this directory are alternative sounds that can be used if you want to customize the sound effects.

## Usage

To use these alternative sounds in the app:

1. Copy the desired `.wav` file(s) to `PasteMine/PasteMine/Resources/Sounds/`
2. Update the sound references in `Services/SoundService.swift` if needed
3. Rebuild the application

## File Information

- **Format**: WAV (Waveform Audio File Format)
- **Files**: 1.wav, 2.wav, 3.wav, 4.wav, 5.wav, 6.wav
- **Purpose**: Sound effect options for clipboard operations
