# Contributing

## Development

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) test harness.

Run all tests:

```bash
nvim --headless -c "lua require('plenary.test_harness').test_file('tests/test_util.lua')" -c "qa"
```

### Test structure

Tests are parameterized with Latin and Cyrillic variants to ensure
non-ASCII character support. Each base scenario runs for both scripts.
New filtering logic should add corresponding Cyrillic test cases.
