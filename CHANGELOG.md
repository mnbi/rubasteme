## [Unreleased]
- (nothing to record here)

## [0.1.2] - 2021-05-20
### Added
- Add a singleton method, `version` to Parser class.

## [0.1.1] - 2021-05-20
### Changed
- Change the timing to pass a lexer instance to a Parser object:
  - 0.1.0: initialize Parser object,
    - `Parser.new(lexer)`
  - 0.1.1: call parser method.
    - `parser = Parser.new; parser.parse(lexer)`

## [0.1.0] - 2021-05-20
- Initial release
