# AutoPie — verified Android / Termux installation

This branch includes upstream AutoPie commit
`8c5e83b119b3d7517141c704b8d17a6490a8820b`, which is the same commit tagged
upstream as `v0.19.3-beta`.

The published upstream APK for that exact source revision is:

- Asset: `AutoPie-v0.19.3-beta-aarch64.apk`
- Architecture: `aarch64 / arm64-v8a`
- Package: `com.autopi`
- AutoPie minSdk: API 27
- AutoPie targetSdk: API 28
- SHA-256: `c1d140a165f09af8433e8d0b855a363f8a394477038a1b1cb1951f9e444ef7a7`

## Recommended installation from Termux

From a clone of this fork:

```bash
cd ~/AutoPie
bash scripts/autopie-doctor-termux.sh
bash scripts/install-verified-termux.sh
```

The installer downloads only the APK matching the source revision above, verifies
its SHA-256, and then opens Android's system Package Installer.

Android intentionally requires the final visible **Install** confirmation for a
sideloaded APK. If Android blocks the installer, enable **Install unknown apps**
for Termux, then run the installer again.

## Clone first, if needed

```bash
cd ~
pkg update
pkg install -y git curl coreutils termux-tools
git clone https://github.com/azamkassim/AutoPie.git
cd AutoPie
bash scripts/autopie-doctor-termux.sh
bash scripts/install-verified-termux.sh
```

## Important provenance note

The APK is signed by the upstream AutoPie release key, not by a new key belonging
to this fork. That is deliberate for this source-identical revision: it avoids an
unnecessary signing-key fork and permits normal upgrades from the same upstream
signing lineage.

Once this fork contains code changes that differ from upstream, create and
protect a dedicated release signing key before distributing a fork-specific APK.
Do not commit a keystore or signing password to Git.
