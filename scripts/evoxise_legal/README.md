# Evoxise legal pages

`build.py` writes the Evoxise privacy policy, the cookies page and the fixes to the terms (VOP) into a retrieved copy of the Evoxise site. `content.py` holds the privacy and cookies texts.

Deployed to dev9 and PROD on 2026-10-28. The texts are a draft and need a lawyer's review.

## What it changes

- `views/ochranaOsobnýchÚdajov.json`: replaces the HTML block with the text from `content.PRIVACY`.
- `views/vseobecneObchodnePodmienky.json`: targeted fixes. The operator is Evoxise s.r.o. (the template named livFuture s.r.o.), contacts come from the site footer, Bratislava and Revolut payments are added, zákon 108/2024 replaces 250/2007, and the article references are corrected. Čl. 11 now points to the privacy page. New čl. 12 (withdrawal from distance contracts) and čl. 13 (alternative dispute resolution, SOI), and Záverečné ustanovenia become čl. 14.
- New page `/s/cookies` (`routes/cookies.json`, `views/cookies.json`, route `cookies__c`), a copy of the privacy page layout.
- `lwc/homePageFooter`: adds a "Cookies" link.

Every VOP fix asserts that the original text is present. If someone edits the page in Experience Builder first, the script stops instead of guessing.

## Run

Always start from what is in the target org. Never deploy a bundle retrieved from another org, because the Evoxise pages differ between dev9 and PROD.

```bash
# in any SFDX project folder, with <work> = the folder that contains evxlegal/
sf project retrieve start -o <org> -m ExperienceBundle:Evoxise1 --target-metadata-dir <work>/evx --unzip
sf project retrieve start -o <org> -m LightningComponentBundle:homePageFooter --target-metadata-dir <work>/evxlwc --unzip
cd <work>/evxlegal && python build.py          # EVX_DIR / EVX_LWC_DIR override the folder names
sf project deploy start -o <org> --metadata-dir <work>/evx/unpackaged/unpackaged
sf project deploy start -o <org> --metadata-dir <work>/evxlwc/unpackaged/unpackaged
sf community publish -o <org> --name Evoxise
```

Deploy the bundle before the footer, so the footer link has a page to open.

The cookies table lists the cookies the site set on 2026-10-28 plus `cookieyes-consent`, which appears once CookieYes is installed. Update the table when a tag or script is added.
