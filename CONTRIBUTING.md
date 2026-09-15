# Contributing to Mistpaw

Mistpaw is a single-level Godot ARPG experiment. The MVP is complete; the current
scope is reproducibility, bug fixes and small improvements to existing systems.
There is no commitment to expand it into a commercial game or general framework.

- Report bugs with the game version, OS/GPU, renderer, reproduction steps and,
  where useful, a screenshot. Avoid including credentials or private files.
- Discuss larger changes in an issue before implementation. Keep pull requests
  focused and explain the behavior before and after the change.
- Run the relevant checks listed in README. Rendering changes need actual
  screenshots and renderer details; a headless test cannot prove visual quality.
- Do not commit `.godot/`, builds, credentials, temporary captures or recordings.
- Original code contributions are accepted under MIT. Any new media must include
  its source and explicit license; do not assume existing game art is reusable
  under MIT. See ASSET_LICENSES.md.

The game runs without external API keys. Asset-generation scripts are optional
production tooling and may require the original developer's tools or services.
