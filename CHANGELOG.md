## [Unreleased]
- (nothing to record here)

## [0.1.5] - 2021-06-09
### Added
- Add a new node to represent `case` expression and its parsing.

### Changed
- Refactor parser to parse in 2 phases.

### Fixed
- Fix #5: incorrect parsing with internal definition at wrong
  position.

## [0.1.4] - 2021-05-31
### Added
- Add a new node to represent sequence. (#3)
- Incorporate missing methods to ListNode from rbsiev project.

### Fixed
- Fix #2: typo in the version string.

## [0.1.3] - 2021-05-20
### Fixed
- Change a method name of AST::CondNode.
  - `#cond_clause` -> `#cond_clauses`
- Modify the timing to pass lexer to parser in `exe/rubasteme`.
- Fix #1: `:ast_vector` is missing in AST::AST_NODE_TYPE.

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
