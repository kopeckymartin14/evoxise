# Evoxise legal texts (draft 2026-10-28, needs lawyer review).
# Blocks: ('h', text) heading, ('p', text) paragraph, ('ul', [items]), ('table', head, rows).
# **bold** marks bold text; [text](href) marks a link.

COMPANY = [
    ('p', '**Evoxise s.r.o.**, so sídlom Trnavská 59, 902 01 Pezinok, IČO: 56 524 153, DIČ: 2122339010, zapísaná v Obchodnom registri Mestského súdu Bratislava III, oddiel Sro, vložka č. 181717/B (ďalej len „Prevádzkovateľ“).'),
    ('ul', [
        'prevádzka Pezinok: Hrnčiarska 2/B, 902 01 Pezinok,',
        'prevádzka Bratislava: Bratislava – Kramáre (otvorenie v januári 2027),',
        'e-mail: [evoxise@evoxise-gym.com](mailto:evoxise@evoxise-gym.com),',
        'telefón: [0944 609 553](tel:+421944609553), Pezinok [0905 832 259](tel:+421905832259), Bratislava [0904 896 224](tel:+421904896224).',
    ]),
]

PRIVACY = [
    ('title', 'Informácia o spracúvaní osobných údajov'),
    ('p', 'Táto informácia vysvetľuje, ako spoločnosť Evoxise s.r.o. spracúva osobné údaje klientov, záujemcov, účastníkov podujatí a návštevníkov webu www.evoxise.sk podľa Nariadenia Európskeho parlamentu a Rady (EÚ) 2016/679 (ďalej len „GDPR“) a zákona č. 18/2018 Z. z. o ochrane osobných údajov.'),
    ('h', 'Prevádzkovateľ'),
    ('p', 'Prevádzkovateľom osobných údajov je:'),
] + COMPANY + [
    ('p', 'Vo veciach ochrany osobných údajov nás kontaktujte e-mailom alebo písomne na adrese sídla.'),

    ('h', 'Na aké účely a na akom právnom základe údaje spracúvame'),
    ('p', '**a) Registrácia a klientsky účet**'),
    ('p', 'Meno, priezvisko, e-mail, telefón, prípadne názov firmy a informácia, odkiaľ ste sa o nás dozvedeli. Údaje potrebujeme na vytvorenie a vedenie vášho účtu v Klientskej zóne. Právny základ: plnenie zmluvy a opatrenia pred jej uzavretím (čl. 6 ods. 1 písm. b) GDPR).'),
    ('p', '**b) Rezervácie tréningov**'),
    ('p', 'Údaje o rezerváciách prvého tréningu zdarma, individuálnych a skupinových tréningov, ich termínoch, zrušeniach a účasti. Právny základ: plnenie zmluvy (čl. 6 ods. 1 písm. b) GDPR).'),
    ('p', '**c) Platby, kredit, darčekové poukazy a tovar**'),
    ('p', 'Údaje o nákupe kreditu, darčekových poukazov a tovaru (Evoxise Merch) a o platbe. Online platby spracúva platobná brána Revolut. Údaje o vašej platobnej karte nevidíme ani neukladáme. Pri darčekovom poukaze spracúvame aj meno a e-mail obdarovaného, ktoré nám poskytnete. Právny základ: plnenie zmluvy (čl. 6 ods. 1 písm. b) GDPR).'),
    ('p', '**d) Účtovné a daňové povinnosti**'),
    ('p', 'Údaje na faktúrach a účtovných dokladoch. Právny základ: plnenie zákonnej povinnosti (čl. 6 ods. 1 písm. c) GDPR), najmä podľa zákona č. 431/2002 Z. z. o účtovníctve.'),
    ('p', '**e) Meranie zloženia tela Accuniq**'),
    ('p', 'Ak sa rozhodnete pre meranie, spracúvame jeho výsledky (napríklad hmotnosť, podiel svalov a tuku, viscerálny tuk, celkové skóre) a ich vyhodnotenie s odporúčaniami pre tréning. Ide o údaje týkajúce sa zdravia, ktoré spracúvame len na základe vášho výslovného súhlasu (čl. 9 ods. 2 písm. a) GDPR). Súhlas môžete kedykoľvek odvolať. Na prípravu textového vyhodnotenia môžeme použiť nástroj umelej inteligencie. Vyhodnotenie slúži len ako podklad pre tréning a nerobia sa na jeho základe rozhodnutia s právnymi účinkami.'),
    ('p', '**f) Súťaže a podujatia (Eight Challenge, X-Challenge a ďalšie)**'),
    ('p', 'Meno, e-mail, kategória, vekové pásmo a údaje potrebné na organizáciu podujatia. Pri účastníkoch mladších ako 18 rokov spracúvame aj meno zákonného zástupcu, ktorý za účastníka podpisuje vyhlásenie o účasti. Výsledky s menami účastníkov nezverejňujeme. Právny základ: plnenie zmluvy (čl. 6 ods. 1 písm. b) GDPR).'),
    ('p', '**g) Odporúčanie známeho**'),
    ('p', 'Ak nám odporučíte známeho, spracúvame jeho kontaktné údaje, ktoré nám poskytnete, aby sme mu mohli poslať pozvánku. Odporučte nás prosím len osobe, ktorá s tým súhlasí. Právny základ: oprávnený záujem (čl. 6 ods. 1 písm. f) GDPR).'),
    ('p', '**h) Waitlist a novinky e-mailom**'),
    ('p', 'Ak sa prihlásite na waitlist (napríklad pre otvorenie prevádzky v Bratislave) alebo na odber noviniek, spracúvame váš e-mail a posielame vám informácie a ponuky Evoxise. Právny základ: váš súhlas (čl. 6 ods. 1 písm. a) GDPR a § 116 zákona č. 452/2021 Z. z. o elektronických komunikáciách). Klientom môžeme posielať ponuky podobných služieb aj bez súhlasu. Z odberu sa môžete kedykoľvek odhlásiť odkazom v každom e-maile.'),
    ('p', '**i) Otázky, podnety a sťažnosti**'),
    ('p', 'Údaje, ktoré nám pošlete e-mailom, telefonicky, cez sociálne siete alebo priamo na prevádzke. Na prípravu odpovede na vašu otázku môžeme použiť nástroj umelej inteligencie. Odpoveď vychádza z našich informácií o službách. Právny základ: oprávnený záujem na komunikácii s klientmi (čl. 6 ods. 1 písm. f) GDPR).'),
    ('p', '**j) Analytika a marketing na webe**'),
    ('p', 'Ak s tým súhlasíte v nastaveniach cookies, používame Google Analytics, Google Ads a Meta Pixel. Pomáhajú nám merať návštevnosť webu a účinnosť reklamy a zobrazovať reklamu na sociálnych sieťach a vo vyhľadávači. Tieto nástroje môžu vytvárať profil vašich záujmov. Právny základ: váš súhlas (čl. 6 ods. 1 písm. a) GDPR a § 109 zákona č. 452/2021 Z. z.). Podrobnosti nájdete na stránke [Cookies](/s/cookies).'),
    ('p', '**k) Kamerový systém**'),
    ('p', 'Priestory prevádzok (tréningový priestor a vstup) sú monitorované kamerovým systémom na ochranu zdravia a bezpečnosti osôb a ochranu majetku. Právny základ: oprávnený záujem (čl. 6 ods. 1 písm. f) GDPR).'),
    ('p', '**l) Fotografie a videozáznamy**'),
    ('p', 'Fotografie a videá z tréningov a podujatí zverejňujeme na webe a sociálnych sieťach len so súhlasom zobrazenej osoby (čl. 6 ods. 1 písm. a) GDPR). Súhlas môžete kedykoľvek odvolať.'),

    ('h', 'Komu údaje poskytujeme'),
    ('p', 'K údajom majú prístup poverení zamestnanci a tréneri Prevádzkovateľa. Ďalej ich spracúvajú naši zmluvní partneri (sprostredkovatelia), a to len podľa našich pokynov:'),
    ('ul', [
        '**Salesforce** – systém, v ktorom beží web, Klientska zóna, rezervácie a odosielanie e-mailov,',
        'dodávateľ, ktorý pre nás spravuje systém Salesforce a web,',
        '**Revolut** – platobná brána pre online platby,',
        '**Anthropic** – nástroj umelej inteligencie na prípravu odpovedí a vyhodnotení,',
        '**Google** (Analytics, Ads, písma Google Fonts) a **Meta** (Facebook, Instagram) – len v rozsahu podľa nastavení cookies,',
        'externá účtovná kancelária,',
        'správca kamerového systému.',
    ]),
    ('p', 'Údaje poskytujeme aj orgánom verejnej moci, ak nám to ukladá zákon.'),

    ('h', 'Prenos údajov mimo Európskej únie'),
    ('p', 'Niektorí z partnerov (Salesforce, Google, Meta, Anthropic) môžu údaje spracúvať aj v USA. Prenos je chránený rozhodnutím Európskej komisie o primeranosti (EU-US Data Privacy Framework) alebo štandardnými zmluvnými doložkami Európskej komisie.'),

    ('h', 'Ako dlho údaje uchovávame'),
    ('ul', [
        'klientsky účet, rezervácie a kredit: počas trvania zmluvného vzťahu a najviac 6 mesiacov po skončení platnosti kreditu alebo permanentky, ak zákon nevyžaduje dlhšiu dobu,',
        'účtovné doklady: 10 rokov po roku, ktorého sa týkajú,',
        'výsledky merania Accuniq: do odvolania súhlasu, najneskôr do zrušenia klientskeho účtu,',
        'súťaže a podujatia: počas prípravy a konania podujatia a po ňom, kým je to potrebné na vybavenie nárokov,',
        'waitlist a novinky e-mailom: do odhlásenia alebo odvolania súhlasu,',
        'otázky a podnety: kým ich vybavíme a kým je to potrebné na prípadné nároky,',
        'záznamy kamerového systému: 15 dní,',
        'fotografie a videá: do odvolania súhlasu,',
        'cookies: podľa doby uvedenej na stránke [Cookies](/s/cookies).',
    ]),

    ('h', 'Vaše práva'),
    ('p', 'Máte právo:'),
    ('ul', [
        'na prístup k svojim osobným údajom (čl. 15 GDPR),',
        'na opravu nesprávnych údajov (čl. 16 GDPR),',
        'na vymazanie údajov (čl. 17 GDPR),',
        'na obmedzenie spracúvania (čl. 18 GDPR),',
        'na prenosnosť údajov (čl. 20 GDPR),',
        'namietať proti spracúvaniu na základe oprávneného záujmu a proti priamemu marketingu (čl. 21 GDPR),',
        'kedykoľvek odvolať súhlas; odvolanie nemá vplyv na zákonnosť spracúvania pred jeho odvolaním.',
    ]),
    ('p', 'Práva uplatníte e-mailom na [evoxise@evoxise-gym.com](mailto:evoxise@evoxise-gym.com) alebo listom na adrese Evoxise s.r.o., Trnavská 59, 902 01 Pezinok. Odpovieme vám najneskôr do jedného mesiaca.'),
    ('p', 'Ak sa domnievate, že vaše údaje spracúvame v rozpore s predpismi, môžete podať návrh na začatie konania na Úrad na ochranu osobných údajov Slovenskej republiky, Hraničná 12, 820 07 Bratislava 27, [www.dataprotection.gov.sk](https://www.dataprotection.gov.sk).'),

    ('h', 'Povinnosť poskytnúť údaje'),
    ('p', 'Údaje potrebné na registráciu, rezerváciu, platbu alebo účasť na podujatí sú podmienkou uzavretia zmluvy. Bez nich vám službu nevieme poskytnúť. Poskytnutie údajov na základe súhlasu je dobrovoľné.'),

    ('h', 'Automatizované rozhodovanie'),
    ('p', 'Nerobíme rozhodnutia s právnymi účinkami založené výlučne na automatizovanom spracúvaní. Profilovanie na reklamné účely prebieha len so súhlasom podľa písm. j).'),

    ('updated', 'Posledná aktualizácia: 28. 10. 2026'),
]

COOKIES = [
    ('title', 'Súbory cookies'),
    ('p', 'Cookies sú malé textové súbory, ktoré web ukladá vo vašom prehliadači. Podobne funguje aj lokálne úložisko prehliadača (localStorage). Na tejto stránke nájdete, aké cookies web www.evoxise.sk používa a na čo slúžia.'),
    ('h', 'Nevyhnutné cookies'),
    ('p', 'Sú potrebné na fungovanie webu, prihlásenie do Klientskej zóny a zapamätanie vašej voľby cookies. Ukladáme ich bez súhlasu podľa § 109 zákona č. 452/2021 Z. z. o elektronických komunikáciách.'),
    ('table', ['Názov', 'Poskytovateľ', 'Účel', 'Platnosť'], [
        ['renderCtx', 'Salesforce', 'Technické nastavenie zobrazenia stránky.', 'do zatvorenia prehliadača'],
        ['CookieConsentPolicy, LSKey-c$CookieConsentPolicy', 'Salesforce', 'Technické nastavenie platformy Salesforce.', '1 rok'],
        ['sid, oid a ďalšie cookies prihlásenia', 'Salesforce', 'Prihlásenie do Klientskej zóny.', 'do odhlásenia'],
        ['cookieyes-consent', 'CookieYes', 'Zapamätá si vašu voľbu cookies.', '1 rok'],
    ]),
    ('h', 'Štatistické cookies'),
    ('p', 'Pomáhajú nám zistiť, ako návštevníci web používajú. Ukladáme ich len s vaším súhlasom.'),
    ('table', ['Názov', 'Poskytovateľ', 'Účel', 'Platnosť'], [
        ['_ga, _ga_FQ8S75QVHN', 'Google Analytics', 'Rozlíšenie návštevníkov a meranie návštevnosti.', '400 dní'],
        ['pctrk', 'Salesforce', 'Meranie návštev stránok webu.', '1 rok'],
    ]),
    ('h', 'Marketingové cookies'),
    ('p', 'Slúžia na meranie účinnosti reklamy a zobrazovanie reklamy na sociálnych sieťach a vo vyhľadávači. Ukladáme ich len s vaším súhlasom.'),
    ('table', ['Názov', 'Poskytovateľ', 'Účel', 'Platnosť'], [
        ['_gcl_au, _gcl_ls (localStorage)', 'Google Ads', 'Meranie konverzií z reklám Google.', '90 dní'],
        ['_fbp', 'Meta (Facebook, Instagram)', 'Meranie a zobrazovanie reklamy na Facebooku a Instagrame.', '90 dní'],
    ]),
    ('h', 'Ako zmeniť alebo odvolať súhlas'),
    ('p', 'Pri prvej návšteve webu si vyberiete, ktoré cookies povolíte. Voľbu môžete kedykoľvek zmeniť alebo súhlas odvolať cez ikonu nastavení cookies v rohu stránky. Cookies môžete vymazať alebo zablokovať aj v nastaveniach prehliadača. Ak zablokujete nevyhnutné cookies, niektoré časti webu, napríklad Klientska zóna, nemusia fungovať.'),
    ('h', 'Osobné údaje'),
    ('p', 'Ako spracúvame osobné údaje, vrátane prenosu údajov do USA pri službách Google a Meta, vysvetľuje stránka [Ochrana osobných údajov](/s/ochrana-osobnych-udajov).'),
    ('updated', 'Posledná aktualizácia: 28. 10. 2026'),
]
