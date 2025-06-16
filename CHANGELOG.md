# Changelog

## [0.1.0] - 2025-06-16
### Breaking changes:
- timezoneOffset is now an integer representing hours offset instead of a formatted string
- Existing Hive box data will be cleared on first run due to schema change
- fix: atom time format and data type adjustments

### Enhnancements & Fixes:
- Update userTime format to use ISO 8601 with timezone (YYYY-MM-DDTHH:mm:ss+HH:00)
- Change timezoneOffset from String to int (using hours offset)
- Fix Hive box initialization to handle schema changes
- Fix documentation HTML entities in comments
- Remove unused intl package import

## [0.0.1] - 2025-06-10
### Initial release
- Just initial release.
