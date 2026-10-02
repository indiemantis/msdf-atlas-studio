# Contributing to MSDF Atlas Studio

Thank you for your interest in contributing to **MSDF Atlas Studio**! We welcome bug reports, feature suggestions, documentation improvements, and code pull requests.

---

## How Contributions Work

1. **Issues First**: For significant new features or breaking changes, please open an Issue to discuss the approach before opening a Pull Request.
2. **Fork & Branch**: Fork this repository, clone it with submodules, and create a feature branch (`feature/your-feature-name` or `fix/issue-description`).
3. **Commit Guidelines**: Write clear, descriptive commit messages.
4. **Attribution**: When your Pull Request is reviewed and merged, your name and GitHub profile will be added to [CONTRIBUTORS.md](CONTRIBUTORS.md)!

---

## Development Setup

1. **Clone recursively with submodules:**
   ```bash
   git clone --recursive https://github.com/sachinthankachan/msdf-atlas-studio.git
   cd msdf-atlas-studio
   ```

2. **Build the C++ GDExtension backend:**
   ```bash
   cd src_cpp
   scons platform=linux target=template_release
   cd ..
   ```

3. **Open and test in Godot 4.3+:**
   ```bash
   godot --path .
   ```

---

## Code Guidelines

* **GDScript**: Follow the official [Godot GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) (tabs for indentation, static typing where possible).
* **C++ Backend**: C++17 standard, formatted consistently with existing source files.
* **Comments**:
  * Write natural, human-like explanations only when the logic is non-obvious.
  * Avoid redundant or obvious comments.
  * Use lowercase phrasing without hyphens in comments.
* **Testing**: Ensure the project compiles without warnings and passes headless execution:
  ```bash
  godot --headless --quit
  ```

---

## Community

Please treat everyone with respect and empathy. We are committed to maintaining a welcoming and productive open-source environment.
