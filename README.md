# koto
casual + conversational chat bot to help japanese language learners

## Running

Open `Koto.xcodeproj` in Xcode, pick an iPhone simulator, and press Run (⌘R).

### API key

こと runs on Claude (Haiku 5.5) and calls the API directly from the app, which is fine for a
personal app but not for one shared with others. To set it up:

1. Copy `Secrets.example.plist` to `Koto/Secrets.plist` (git-ignored).
2. Replace `PASTE_YOUR_KEY_HERE` with your key from console.anthropic.com.
3. Rebuild.

Without a key, the chat shows an error asking for one. `FakeChatService` is a scripted stand-in
used by SwiftUI previews.

## Credits

Dictionary: [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html) by EDRDG, CC BY-SA 4.0, via
[jmdict-simplified](https://github.com/scriptin/jmdict-simplified). Rebuild it with
`tools/build_dictionary.py`.
