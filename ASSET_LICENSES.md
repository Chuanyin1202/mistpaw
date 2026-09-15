# Asset licensing and attribution

The root MIT license applies to original source code, shaders, scene/configuration
files, build/test scripts and documentation. It does **not** license the artwork,
audio, fonts, logos, screenshots or video recordings as MIT.

## Game media

Images, animations and audio under `assets/`, image/media files under `web/`, and
recordings/screenshots under `docs/` are separate from the MIT-licensed code.
Unless a file has a separate license notice, no general-purpose asset reuse
license is granted. To the extent the maintainer holds the relevant rights,
these files may be used to run and evaluate this Mistpaw demo. Reuse in other
games, asset packs, branding or commercial products requires separate permission.
Permissions provided by the hosting platform's terms remain unaffected.

Much of the artwork was generated with OpenAI image tools; some audio was
generated with ElevenLabs, and some was synthesized by project scripts.
`assets/provenance.json` records available origins, generation/processing notes
and hashes. A provenance entry is not itself a redistribution license. Entries
referring to `../onepaw` describe the original local source, not a build dependency.
This notice makes no claim of exclusive copyright over AI-generated material.

Code within `assets/source/` is MIT-licensed; the media it processes is not
automatically covered by that license. Third-party tools and services retain
their own terms. No service API key is required to play the game.

## Fonts

The bundled Noto Sans TC fonts are licensed under the SIL Open Font License 1.1.
See the complete license and copyright notices in [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt).

## Engine

Godot is a separate MIT-licensed dependency, not vendored in this source tree.
Redistributors of exported engine binaries must retain the engine's applicable
license and third-party notices. See <https://godotengine.org/license/>.

The project is open-source **code** with separately licensed media, not an
all-assets-permissively-licensed game kit.
