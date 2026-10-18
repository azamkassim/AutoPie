# Local Share Inspector — offline pilot

Requires AutoPie **v0.19.3-beta** and its completed embedded Termux bootstrap.
Use the verified installer described in [TERMUX_INSTALL.md](../../TERMUX_INSTALL.md).
The older v0.19.0-beta input-export code has an upstream shell-quoting fix;
do not use this pilot on that version.

## Add the command

1. Open AutoPie, tap **+**, and choose **Share**.
2. Name it **Local Share Inspector**.
3. Paste the `command` value from `commands.json`: `#@PYTHON`, then
   `#@OPEN_LOGS`, then the complete contents of `inspect_share.py`.
   Keep actual line breaks, rather than JSON's escaped `\n` characters.
4. Save. Share the sample below from a notes app using Android **Share → AutoPie**,
   then select **Local Share Inspector**.
5. Check the output log or command history for one `#@AUTOPIE` JSON result.
   If useful, use command details → **Add to Home Screen**.

`commands.json` is a recipe snippet. Do not replace your existing AutoSec
configuration with it. Advanced users can merge the single entry into their
existing JSON object after making a backup and ensuring the ID is unused.

Sample input:

```text
Semak pautan ini:
https://example.com/report
https://example.com/report
```

Expected: `status: ok`, `lines: 3`, and one unique URL with host `example.com`.
The command counts characters, lines and whitespace-separated words, and extracts
HTTP(S) links. It neither fetches links nor evaluates shared text. This is a
syntax inspector, not a link-safety verdict or document summarizer. It rejects
inputs above 65,536 characters. File contents are never read.

AutoPie keeps normal command logs, and structured results can appear on attached
widgets. URLs, including query parameters, can contain confidential tokens. Use
public sample text for this pilot; no credentials, customer data or login links.
The script makes no network calls and creates no output files, but AutoPie's own
logging still applies. Browser login/cookie integration is unnecessary.

## Validate on the host

```sh
python3 -m unittest discover -s examples/local-share -p 'test_*.py' -v
```

Host tests cover the recipe's actual inline Python, malformed links, literal shell
syntax, Unicode and size limits. Android share UI, APK installation and background
execution require a separate device check. This pilot does not configure observers,
schedules, remote control or a connection to a business system.
