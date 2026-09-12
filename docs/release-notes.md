# Mistpaw 0.1.0

Mistpaw is a single-level HD-2D-inspired action RPG demo set in the misty Qingwu Forest.

The release includes a complete playable route from the opening forest encounters to the forest boss, with keyboard controls on desktop and touch controls on mobile Web. Combat includes manual combo attacks, heavy attacks, spinning attacks, dodges, double jumps, three relic styles, enemy groups, loot collection, boss attack patterns, guard break, music changes, and a retry result screen.

The desktop build targets Godot 4.7.2 with Metal Forward+. The Web build uses the compatibility renderer and is hosted at [mistpaw.eighti.app](https://mistpaw.eighti.app/). The Web version runs game logic on the player's device; the Pi5 only serves the files through HTTPS.

The final showcase recordings are kept beside this document for review. Intermediate screenshots, frame captures, probes, logs, and superseded recordings are intentionally excluded from the release workspace.

## Local visual update — not deployed

The `feat/sunlit-forest` branch adds a sunlit distant forest layer, warmer direct light with cool ambient fill, moving alpha-tested canopy shadows, stone surface relief and wetness, revised water ripples/reflections, and reduced depth-of-field blur. Native rendering uses 4× MSAA; Web retains its existing renderer and disables MSAA. The distant forest is generated artwork; shadows, surface lighting, water and volumetric atmosphere are rendered by Godot.

The wide terrace previously had reversed triangle winding, hiding its intended surface. Its front faces now point upward. The thin surface receives shadows while the solid terrace underneath casts them, avoiding Compatibility self-shadow bands.

The follow-up material pass adds generated irregular flagstone albedo and a single shallow bevelled paving mesh per bank. Slab faces have real edge normals and varied roughness; all relief stays between 0.062 and 0.105 world units, with no added collision. Foliage now uses the main camera orientation in both visible and shadow passes, removing the diagonal self-shadow cuts. Sunlight comes from behind the bank to reflect toward the camera, with soft front fill to preserve actor readability. Water keeps dynamic wave normals and screen-space reflections; an experimental cached probe was discarded after it produced visible reflection blocks.

Validation on Apple M4 at 1280×720: the scripted full combat route completed with all four pickups and boss phases; frame interval median 16.67 ms, p95 17.99 ms, maximum 36.56 ms. A subsequent crowded-effects benchmark across all three quality profiles measured medians near 16.7 ms and p95 below 18.2 ms. These are local scripted measurements, not mobile/browser performance guarantees. All seven atmosphere lifecycle checks passed. Fixed-camera Forward+ and Compatibility renders were inspected; screenshots and benchmark outputs stay under ignored `build/verification/`.

After the follow-up paving pass, the final crowded-effects benchmark measured 16.67 ms median / 17.86 ms p95 on the finest profile, and p95 below 18.2 ms for all profiles. Ten geometry checks passed for bounds, upward normals, vertex budget, deterministic layout and absence of collision bodies. Shader implementation references: [Godot spatial shader camera matrices](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html).

This update improves the reference's lighting hierarchy, but does not reproduce the AI concept's geometric density or every reflection. The production URL and published recordings still show version 0.1.0.
