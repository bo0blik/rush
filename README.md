# Rush — Forest Pass demo

**[Play in your browser](https://bo0blik.github.io/rush/)**

A pixel art motorcycle road demo made with Godot 4.7.2. Drive through a rural forest road, overtake traffic, change motorcycles and customize the rider.

The dashboard uses an analog speedometer and warning lamps. The scenery includes eight layers of distant forest, animated insects and birds, and grazing/walking cattle and sheep. Acceleration adds peripheral radial blur; F3 toggles motion effects. These latest visual changes are published for user playtesting.

## Playing

Use a desktop keyboard and a browser with WebGL 2. Click the game to focus it and enable audio. The game fills the browser window; click **На весь экран** in the top-right corner to enter full screen.

- **W / arrow up**: throttle; **A/D**: steering.
- **S**: front brake; **Space**: rear brake.
- **Q/E**: gears; **M**: automatic transmission.
- **F2**: graphics preset; **F3**: speed effects; **F4**: motorcycle.
- **F5–F8**: helmet, jacket, trousers and boots.
- **Z/X**: punch; **C/V**: kick; **F9**: test collision.
- **R**: restart; **Esc**: pause.

The simulation is tuned for gameplay and is not a calibrated motorcycle simulator. Mobile touch controls are not implemented.

## Development and publishing

Open `project.godot` with Godot 4.7.2. Editor-only MCP tools are not included in this publishing project. Reference documentation remains in [ref/](ref/README.md).

The `Web demo` workflow imports the project, runs gameplay smoke checks, exports a single-threaded Web build and deploys it to GitHub Pages after changes land on `main`. Compiled builds are stored as workflow artifacts rather than in Git history.

Local export:

```sh
python tools/install_web_template.py 4.7.2
Godot --headless --editor --import
mkdir -p build/web
Godot --headless --export-release Web "$PWD/build/web/index.html"
python -m http.server 8765 --directory build/web
```

The Web preset exports all runtime resources, including shader and sprite dependencies loaded from GDScript, and excludes reference files, tests and development tools. It does not require cross-origin isolation headers. The custom HTML shell and Web feature overrides fill the viewport while preserving sprite proportions.
