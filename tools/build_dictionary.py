#!/usr/bin/env python3
"""Convert JMdict (jmdict-simplified JSON) into the compact SQLite file the app bundles.

Usage:
    python3 tools/build_dictionary.py path/to/jmdict-eng-X.json Koto/Resources/jmdict.sqlite

Source: https://github.com/scriptin/jmdict-simplified (JMdict by EDRDG, CC BY-SA 4.0).
"""

import json
import os
import sqlite3
import sys

MAX_SENSES = 3
MAX_GLOSSES = 3
# Usage notes worth showing a learner of casual Japanese.
INTERESTING_MISC = {
    "col", "sl", "net-sl", "uk", "abbr", "hon", "hum", "pol", "vulg", "joc",
    "fam", "male", "fem", "derog", "dated", "arch", "rare", "on-mim", "id",
}


def convert(source_path: str, output_path: str) -> None:
    with open(source_path, encoding="utf-8") as f:
        words = json.load(f)["words"]

    if os.path.exists(output_path):
        os.remove(output_path)
    db = sqlite3.connect(output_path)
    db.executescript(
        """
        CREATE TABLE entries (
            id INTEGER PRIMARY KEY,
            headword TEXT NOT NULL,
            reading TEXT NOT NULL,
            pos TEXT NOT NULL,       -- space-separated JMdict part-of-speech codes
            tags TEXT NOT NULL,      -- space-separated JMdict misc codes
            meanings TEXT NOT NULL,  -- one sense per line
            common INTEGER NOT NULL
        );
        -- Every kanji and kana spelling, for lookup. The primary key doubles as the index.
        CREATE TABLE forms (
            form TEXT NOT NULL,
            entry_id INTEGER NOT NULL,
            common INTEGER NOT NULL,  -- whether this spelling is common, e.g. 行く yes, 行る no
            PRIMARY KEY (form, entry_id)
        ) WITHOUT ROWID;
        """
    )

    entries, forms = [], []
    for word in words:
        senses = word["sense"]
        if not senses:
            continue
        kanji = [k["text"] for k in word["kanji"]]
        kana = [k["text"] for k in word["kana"]]
        usually_kana = "uk" in senses[0]["misc"]
        headword = kana[0] if (usually_kana or not kanji) else kanji[0]
        reading = kana[0] if kana else headword

        pos = []
        for sense in senses:
            for p in sense["partOfSpeech"]:
                if p not in pos:
                    pos.append(p)
        # Usage notes from the main sense only; later senses are often rare slang
        # meanings that would mislabel the whole word (e.g. 行く).
        tags = [m for m in senses[0]["misc"] if m in INTERESTING_MISC]

        meanings = []
        for sense in senses[:MAX_SENSES]:
            glosses = [g["text"] for g in sense["gloss"] if g["lang"] == "eng"][:MAX_GLOSSES]
            if glosses:
                meanings.append("; ".join(glosses))
        if not meanings:
            continue

        common = any(k["common"] for k in word["kanji"] + word["kana"])
        entry_id = int(word["id"])
        entries.append((entry_id, headword, reading, " ".join(pos), " ".join(tags), "\n".join(meanings), int(common)))
        form_common = {}
        for k in word["kanji"] + word["kana"]:
            form_common[k["text"]] = form_common.get(k["text"], False) or k["common"]
        for form, is_common in form_common.items():
            forms.append((form, entry_id, int(is_common)))

    db.executemany("INSERT INTO entries VALUES (?, ?, ?, ?, ?, ?, ?)", entries)
    db.executemany("INSERT INTO forms VALUES (?, ?, ?)", forms)
    db.commit()
    db.execute("VACUUM")
    db.close()
    print(f"{len(entries)} entries, {len(forms)} forms -> {output_path} "
          f"({os.path.getsize(output_path) / 1_048_576:.1f} MB)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    convert(sys.argv[1], sys.argv[2])
