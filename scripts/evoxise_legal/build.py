"""Write the Evoxise privacy, cookies and VOP texts into the retrieved Evoxise1 bundle and the footer LWC."""
import copy
import html
import json
import os
import re
import uuid

import content

HERE = os.path.dirname(os.path.abspath(__file__))
SCRATCH = os.path.dirname(HERE)
B = chr(92)
# EVX_DIR / EVX_LWC_DIR: retrieved metadata folders (evx + evxlwc for dev9, pevx + pevxlwc for PROD).
BUNDLE = B + B + '?' + B + os.path.join(SCRATCH, os.environ.get('EVX_DIR', 'evx'), 'unpackaged', 'unpackaged', 'experiences', 'Evoxise1')
FOOTER = os.path.join(SCRATCH, os.environ.get('EVX_LWC_DIR', 'evxlwc'), 'unpackaged', 'unpackaged', 'lwc', 'homePageFooter', 'homePageFooter.html')

SPAN = '<span style="font-size: 16px; font-family: sans-serif;">{}</span>'
CELL = 'style="padding: 8px 10px; border-bottom: 1px solid #d8d8d8; text-align: left; vertical-align: top; font-size: 15px; font-family: sans-serif;"'


def inline(text):
    out = html.escape(text, quote=False)
    out = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', out)
    return re.sub(r'\[(.+?)\]\((.+?)\)', r'<a href="\2">\1</a>', out)


def render(blocks):
    parts = ['<div style="margin-left: 10px; margin-bottom:10px; max-width: 900px;">']
    for block in blocks:
        kind = block[0]
        if kind == 'title':
            parts.append(f'<p style="text-align: center;"><strong style="font-size: 20px; font-family: sans-serif;">{inline(block[1])}</strong></p>')
        elif kind == 'h':
            parts.append(f'<p style="text-align: center; margin-top: 28px;"><strong style="font-size: 18px; font-family: sans-serif;"><u>{inline(block[1])}</u></strong></p>')
        elif kind == 'p':
            parts.append('<p>' + SPAN.format(inline(block[1])) + '</p>')
        elif kind == 'ul':
            parts.append('<ul>' + ''.join('<li>' + SPAN.format(inline(i)) + '</li>' for i in block[1]) + '</ul>')
        elif kind == 'table':
            head = ''.join(f'<th {CELL}>{inline(c)}</th>' for c in block[1])
            rows = ''.join('<tr>' + ''.join(f'<td {CELL}>{inline(c)}</td>' for c in row) + '</tr>' for row in block[2])
            parts.append(f'<div style="overflow-x: auto;"><table style="width: 100%; border-collapse: collapse; margin: 8px 0 16px;"><thead><tr>{head}</tr></thead><tbody>{rows}</tbody></table></div>')
        elif kind == 'updated':
            parts.append(f'<p style="margin-top: 28px;"><span style="font-size: 14px; font-family: sans-serif; color: #666;">{inline(block[1])}</span></p>')
    parts.append('</div>')
    return '\n'.join(parts)


def html_blocks(node):
    if isinstance(node, dict):
        if node.get('componentName') == 'forceCommunity:htmlBlock':
            yield node
        for value in node.values():
            yield from html_blocks(value)
    elif isinstance(node, list):
        for value in node:
            yield from html_blocks(value)


def load(kind, name):
    with open(BUNDLE + B + kind + B + name + '.json', encoding='utf-8') as f:
        return json.load(f)


def save(kind, name, data):
    with open(BUNDLE + B + kind + B + name + '.json', 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def set_html(view, value):
    blocks = list(html_blocks(view))
    assert len(blocks) == 1, len(blocks)
    blocks[0]['componentAttributes']['richTextValue'] = value


def sub(text, old, new, count=1):
    # The source HTML mixes normal and non-breaking spaces, so a space matches either.
    pattern = re.compile(re.escape(old).replace(re.escape(' '), '[  ]').replace(r'\ ', '[  ]'))
    found = len(pattern.findall(text))
    assert found == count, (old, found)
    return pattern.sub(lambda m: new, text)


def p(text):
    return '\n    <p>\n        ' + SPAN.format(text) + '\n    </p>'


def section(title, paragraphs):
    head = ('\n    <p style="text-align: center;">\n        <strong style="font-size: 16px; font-family: sans-serif;">\n'
            f'            <u>{title}</u>\n        </strong>\n    </p>')
    return head + ''.join(p(x) for x in paragraphs) + p(' ')


def vop(text):
    text = sub(text, 'Tel.:0944 609 553', 'Tel.: 0944 609 553, Pezinok 0905 832 259, Bratislava 0904 896 224')
    text = sub(text, '<u style="font-size: 16px; font-family: sans-serif;">info.evoxise@gmail.com</u>',
               '<a href="mailto:evoxise@evoxise-gym.com" style="font-size: 16px; font-family: sans-serif;">evoxise@evoxise-gym.com</a>')
    text = sub(text, 'Hrnčiarska 2/B 19, 902 01 Pezinok</strong>\n    </p>',
               'Hrnčiarska 2/B, 902 01 Pezinok</strong>\n    </p>\n    <p>\n        <strong style="font-size: 16px; font-family: sans-serif;">Evoxise Bratislava – Kramáre (otvorenie v januári 2027)</strong>\n    </p>')
    text = sub(text, 'prevádzka Prevádzkovateľa, nachádzajúca sa na adrese: Evoxise, Hrnčiarska 2/B , 902 01 Pezinok, v ktorej Prevádzkovateľ poskytuje svoje Služby,',
               'prevádzka Prevádzkovateľa v Pezinku (Hrnčiarska 2/B, 902 01 Pezinok) alebo v Bratislave (Kramáre), v ktorej Prevádzkovateľ poskytuje svoje Služby,')
    text = sub(text, 'Webovej stránkyp revádzkovateľa', 'Webovej stránky Prevádzkovateľa')
    text = sub(text, 'obchodná spoločnosť livFuture s.r.o. , so sídlom: Vajnorská 65, 831 03 Bratislava, IČO: 48240923, spoločnosť zapísaná v obchodnom registri Mestského súdu Bratislava 3, odd.: Sro, vložka č. 105332/B,',
               'obchodná spoločnosť Evoxise s.r.o., so sídlom: Trnavská 59, 902 01 Pezinok, IČO: 56 524 153, spoločnosť zapísaná v Obchodnom registri Mestského súdu Bratislava III, odd.: Sro, vložka č. 181717/B,')
    text = sub(text, 'platbou kartou v Centre Prevádzkovateľa,</span>\n        </li>',
               'platbou kartou v Centre Prevádzkovateľa,</span>\n        </li>\n        <li>\n            <span style="font-size: 16px; font-family: sans-serif;">platbou kartou online na Webovej stránke prostredníctvom platobnej brány Revolut,</span>\n        </li>')
    text = sub(text, 'Klient nemôže žiadať vrátenie Kreditu na cvičenie s ARX strojom, ktorý už u Prevádzkovateľa zakúpil. ',
               'Klient nemôže žiadať vrátenie Kreditu na cvičenie s ARX strojom, ktorý už u Prevádzkovateľa zakúpil, s výnimkou odstúpenia od zmluvy podľa čl. 12 VOP. ')
    text = sub(text, 'zákonom č. 250/2007 Z. z. o ochrane spotrebiteľa v znení neskorších predpisov', 'zákonom č. 108/2024 Z. z. o ochrane spotrebiteľa')
    text = sub(text, 'emailom na </span>\n        <u style="font-size: 16px; font-family: sans-serif;">www.evoxise.sk</u>',
               'emailom na </span>\n        <a href="mailto:evoxise@evoxise-gym.com" style="font-size: 16px; font-family: sans-serif;">evoxise@evoxise-gym.com</a>')
    text = sub(text, 'podľa časti 8.1. bodu 7.', 'podľa časti 9.1. bodu 7.')
    text = sub(text, 'vstupom do Štúdia', 'vstupom do Centra')

    # Section 11: one source of truth for personal data, then withdrawal and dispute resolution.
    start = text.index('<p style="text-align: center;">\n        <strong style="font-size: 16px; font-family: sans-serif;">\n            <u>11. Ochrana osobných údajov</u>')
    end = text.index('<p style="text-align: center;">\n        <strong style="font-size: 16px; font-family: sans-serif;">\n            <u>12. Záverečné ustanovenia</u>')
    new = section('11. Ochrana osobných údajov', [
        'Prevádzkovateľ spracúva osobné údaje Klientov v súlade s nariadením (EÚ) 2016/679 (GDPR) a zákonom č. 18/2018 Z. z. o ochrane osobných údajov. Účely, právne základy, príjemcov, dobu uchovávania a práva Klienta podrobne opisuje dokument <a href="/s/ochrana-osobnych-udajov">Ochrana osobných údajov</a>. Informácie o súboroch cookies sú na stránke <a href="/s/cookies">Cookies</a>.',
    ]) + section('12. Odstúpenie od zmluvy uzavretej na diaľku', [
        'Klient, ktorý je spotrebiteľom a kúpi Kredit, darčekový poukaz alebo tovar prostredníctvom Webovej stránky, má právo odstúpiť od zmluvy bez uvedenia dôvodu do 14 dní od jej uzavretia, pri tovare do 14 dní od jeho prevzatia.',
        'Odstúpenie Klient oznámi e-mailom na evoxise@evoxise-gym.com alebo listom na adresu sídla Prevádzkovateľa. Prevádzkovateľ vráti Klientovi prijaté platby do 14 dní od doručenia odstúpenia, a to rovnakým spôsobom, akým Klient platil.',
        'Ak Klient na základe svojej výslovnej žiadosti začne Kredit čerpať ešte počas lehoty na odstúpenie, uhradí Prevádzkovateľovi pomernú časť ceny za Služby poskytnuté do odstúpenia.',
        'Klient nemá právo odstúpiť od zmluvy o Službách súvisiacich s voľnočasovými aktivitami, ktoré sa podľa zmluvy poskytujú v dohodnutom termíne, napríklad pri rezervácii konkrétneho tréningu alebo registrácii na podujatie s pevným dátumom.',
    ]) + section('13. Alternatívne riešenie sporov a dozor', [
        'Ak Klient nie je spokojný so spôsobom, ktorým Prevádzkovateľ vybavil jeho reklamáciu, alebo sa domnieva, že Prevádzkovateľ porušil jeho práva, môže sa obrátiť na Prevádzkovateľa so žiadosťou o nápravu. Ak Prevádzkovateľ na žiadosť odpovie zamietavo alebo neodpovie do 30 dní od jej odoslania, Klient, ktorý je spotrebiteľom, môže podať návrh na začatie alternatívneho riešenia sporu subjektu alternatívneho riešenia sporov, najmä Slovenskej obchodnej inšpekcii (www.soi.sk), alebo inej oprávnenej právnickej osobe zapísanej v zozname vedenom Ministerstvom hospodárstva Slovenskej republiky.',
        'Dozor nad dodržiavaním povinností Prevádzkovateľa vykonáva Slovenská obchodná inšpekcia, Inšpektorát SOI pre Bratislavský kraj, Bajkalská 21/A, 827 99 Bratislava.',
    ])
    text = text[:start] + new.lstrip('\n ') + '\n    ' + text[end:]
    return sub(text, '<u>12. Záverečné ustanovenia</u>', '<u>14. Záverečné ustanovenia</u>')


def main():
    privacy = load('views', 'ochranaOsobnýchÚdajov')
    set_html(privacy, render(content.PRIVACY))
    save('views', 'ochranaOsobnýchÚdajov', privacy)

    terms = load('views', 'vseobecneObchodnePodmienky')
    block = list(html_blocks(terms))[0]
    block['componentAttributes']['richTextValue'] = vop(block['componentAttributes']['richTextValue'])
    save('views', 'vseobecneObchodnePodmienky', terms)

    # Cookies page: copy of the privacy route and view with new ids.
    ids = {}

    def renew(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key == 'id' and isinstance(value, str):
                    node[key] = ids.setdefault(value, str(uuid.uuid5(uuid.NAMESPACE_URL, 'evoxise/cookies/' + value)))
                else:
                    renew(value)
        elif isinstance(node, list):
            for value in node:
                renew(value)

    view = copy.deepcopy(privacy)
    renew(view)
    view['label'] = 'Cookies'
    view['viewType'] = 'custom-cookies'
    set_html(view, render(content.COOKIES))
    route = load('routes', 'ochranaOsobnýchÚdajov')
    route.update({
        'activeViewId': view['id'],
        'devName': 'cookies__c',
        'id': str(uuid.uuid5(uuid.NAMESPACE_URL, 'evoxise/cookies/route')),
        'label': 'Cookies',
        'routeType': 'custom-cookies',
        'urlPrefix': 'cookies',
    })
    save('views', 'cookies', view)
    save('routes', 'cookies', route)

    with open(FOOTER, encoding='utf-8', newline='') as f:
        footer = f.read()
    if 'cookies__c' not in footer:
        old = '<span data-section="prevadzkovy_poriadok__c" onclick={goToPage}>Prevádzkový poriadok</span>'
        footer = sub(footer, old, old + '\n            <span class="divider">·</span>\n            <span data-section="cookies__c" onclick={goToPage}>Cookies</span>')
        with open(FOOTER, 'w', encoding='utf-8', newline='') as f:
            f.write(footer)
    print('done', route['urlPrefix'], view['id'])


if __name__ == '__main__':
    main()
