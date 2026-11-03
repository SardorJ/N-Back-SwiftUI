# LLM process
## Tools

I used the Cursor agent in Xcode.

## Context given to the model

I used the lab pdf instructions to the cursor agent and asked it to build as the instructions asked for.

## Prompts that shaped the code

### Prompt 1

Det här är uppgiften till en labb. Skriv inget kod ännu. jag vill bara diskutera och få en bild om den här uppgiften först. vad är det vi bygger. hur rekomenderar uppgiften att vi bygger den. vad är bra att tänka och ha med när allt är klart?

**Result:** 
Jag läser labbinstruktionen och tittar snabbt på projektets befintliga struktur så vi kan få en tydlig bild innan vi skriver kod.

It downloaded the lab instructions pdf and read the files

Vad ni bygger

En native N-back-app (ni har redan iOS/SwiftUI-skelettet). Spelet visar stimuli en i taget; spelaren trycker när det aktuella stimulat matchar det från n steg tidigare.

• Visuellt: 3×3-ruta, en cell lyser per event
• Auditivt: talade bokstäver (TTS)
• Dual (högre betyg): båda samtidigt, oberoende sekvenser

Ni har redan MVVM-skelett: ContentView → N_Back_SwiftUIVM → N_BackSwiftUIModel, plus C-logik i nback.c/nback.h som genererar sekvenser (create, getIndexOf) med matchprocent och n.

⸻

Hur uppgiften rekommenderar att ni bygger

Arkitektur: MVVM (MVC ok). ViewModel äger state/spel; Model äger sekvens/poäng; View bara UI. Inte en “god class”.

Rekommenderad AI-workflow: skapa SPEC.md, STYLE.md, CONTEXT.md och ge dem till LLM:en varje session så ni får konsekvent kod.

iOS-hints från labben:
• AVSpeechSynthesizer för bokstäver
• UserDefaults för settings
• Core Data för score-historik
• testa iPhone + iPad

Poängnivåer:
1p bas
2p full

Hårda regler för match-tryck: ignorera före start, efter slut, under första n events; max ett tryck per event; timers måste avbrytas rent när rundan tar slut eller spelaren lämnar skärmen.

⸻

Bra att ha med när allt är klart

Leverans (4 delar):
1. Kod – dokumenterad, tydliga namn, MVVM
2. LLM-process (~1 sida) – verktyg, context-filer, 2–3 prompts, vad AI fick fel
3. Testreport – vad ni testade + testfiler (sekvens, match-rate, first-n, double-press, scoring)
4. Reflection (~½ sida) – en AI-överraskning + en sak ni gjort annorlunda

Muntligt: ni måste kunna förklara varje rad. Fråga 26 öppnar alltid (“vad skrev ni / vad skrev AI”). Övriga frågor täcker sekvens, state machine, scoring, TTS, persistence, layout.

Praktisk checklista i appen:
• Home: high score, stimulus-val, aktuella settings
• Game: rutnät och/eller ljud, event-nummer, korrekta svar, match-knapp, “snäll” animation vid fel
• Dual + settings/historik/layout/a11y om ni siktar på 2p
• Unit tests som faktiskt körs och går grönt

⸻

Kort sagt: ni bygger en kognitiv working-memory-träning med tydlig spel-state, egen (eller C-baserad) sekvenslogik, TTS och MVVM — plus processdokumentation kring AI och tester.

Vill du gå djupare i något först — t.ex. state machine (idle/running/finished), hur C-sekvensen kopplas till SwiftUI, eller vad som räcker för 1p vs 2p?

**What I changed:**

I understood the assignment and then asked it to build from the instructions.

### Prompt 2

jag tycker vi börjar med 1p än så länge. förklara på vägen vad du gör, så att jag förstår.

**Result:**
Bra — vi siktar på 1p först och bygger steg för steg. Jag går igenom vad som redan finns i projektet, så vi vet vad vi kan bygga vidare på.

The Xcode UI for the agents is not the nicest to read, so I am just going to write what it did: it read the files it needed, thought about how it should build it, put in tests, and tried it on a simulator.

And gave me this answer:
1p-versionen är på plats — bygget och alla 4 unit tests gick grönt.

Vad du har nu (i enkla lager)

Model (N_Back_SwiftUIModel.swift) — spelets regler, utan UI
• Genererar sekvenser via din C-kod (create → kopiera till Swift → destroy)
• Vet om något är en match (index vs index - n)
• Räknar hits / misses / false alarms och poäng
• Blockerar tryck: före start, under första n, efter slut, och dubbeltryck

ViewModel (N_Back_SwiftUIVM.swift) — limmet mot UI
• Timer-loop: visa/spela → vänta → nästa event
• TTS med AVSpeechSynthesizer
• Avbryter timern rent när du lämnar spelet

Views
• HomeView — high score, Visual/Sound/Both, settings, Start
• GameView — 3×3-rutnät, Match-knappar, HUD, orange “fel”-animation
• ContentView — byter skärm utifrån phase (VM navigerar inte själv)

Så testar du i Xcode

1. Kör appen (iPhone 17-simulator funkar)
2. Välj t.ex. Visual → Start game
3. När en ruta lyser som för n steg sedan → Position match
4. Prova också Sound / Both

Tester: Cmd+U, eller target N-Back-SwiftUITests.

Poängformel (bra att kunna muntligt)

score = max(0, hits×2 − misses − falseAlarms×2)

⸻

Nästa steg när du vill: gå igenom Model rad för rad tillsammans, eller börja på 2p (settings + UserDefaults, score-historik, m.m.). Vad känns mest nyttigt först?

**What I changed:**
It built the whole thing, and when I tried it I had a problem understanding when it moved or not. So I added a blinking animation by asking it to put it in, and I was happy with how the game was.

### Prompt 3

I did the same thing for 2p and asked it to explain and go through the code row by row so I could understand it. If I did not understand something, I asked.

## What the model got wrong

It built the whole thing, and when I tried it I had a problem understanding when it moved or not. So I added a blinking animation by asking it to put it in, and I was happy with how the game was.

I also made the button interactive when I got it right. On the both game, it did not have a button for when the user thought both were an n-back, so I put that in.

