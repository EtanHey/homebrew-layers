# EtanHey Layers Homebrew Tap

Product front door for Golems installables.

```bash
brew tap etanhey/layers
brew install brainlayer
brew install --cask brainbar
brainlayer setup
```

BrainLayer ships as the Python engine and MCP CLI. BrainBar ships as the notarized
macOS menu-bar app.

## VoiceLayer / VoiceBar

```bash
brew tap etanhey/layers
brew trust --formula etanhey/layers/voicelayer
brew trust --cask etanhey/layers/voicebar
brew install etanhey/layers/voicelayer
brew install --cask etanhey/layers/voicebar
voicelayer setup
```

VoiceLayer ships the CLI/MCP package. VoiceBar ships the notarized macOS menu-bar
app and owns the microphone-permissioned daemon child.

To bring a second Mac onto the same personal VoiceLayer voices, vocabulary, and
daemon secret as an existing Mac:

```bash
voicelayer update --data-mode direct --data-source <source-host>:/Users/<source-user>
```

Then grant VoiceBar the macOS Microphone, Accessibility, and Input Monitoring
permissions on the target Mac and verify a real F5 -> speak -> paste round-trip.
