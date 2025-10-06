# Review System Configuration Template

This template shows all available configuration options for the automated code review system.

## Configuration Options

### AI Configuration

- **`diff_max_chars`**: Maximum number of characters to include from the diff in AI analysis
  - `10000` (default): Truncate diffs larger than 10,000 characters to avoid API limits
  - `0`: Disable truncation, send full diff (use with caution for large changes)
  - Custom number: Set your own limit based on API constraints

### Examples

**Standard Configuration** (recommended):
```json
{
  "ai": {
    "diff_max_chars": 10000
  }
}
```

**No Truncation** (for complete analysis, may cause API errors with large diffs):
```json
{
  "ai": {
    "diff_max_chars": 0
  }
}
```

**Conservative Limit** (for APIs with strict limits):
```json
{
  "ai": {
    "diff_max_chars": 5000
  }
}
```