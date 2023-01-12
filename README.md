# system-symphony

Explore the sonic world of your computer.

`system-syphony` sonifies your computer by transforming its running processes into synthesized sounds.  

## Installation
### Preqrequisites
1. Install [Supercollider](https://supercollider.github.io/downloads) on your current platform.
2. Make sure `sclang` is added to system PATH.
    - **Mac**: `sclang` may be stored at `/Applications/SuperCollider.app/Contents/MacOS/` or `/Applications/SuperCollider/SuperCollider.app/Contents/MacOS/`
    - **Windows**: `sclang` is likely stored at: `C:\Program Files\SuperCollider-<version>`
### Installing Locally
1. Run `pip install .` in `src/system-symphony` directory


### Installing through pypi
1. Run `pip install system-symphony`

## Usage

```
Usage: system-symphony [OPTIONS]

  Explore the sonic world of your computer. Associated supercollider file must
  be running.

Options:
  --poll-rate INTEGER  How fast to poll processes in ms
  --no-sc              Do not launch the supercollider process.
  --help               Show this message and exit.

```


