# Changelog

## [0.2.0] - 2025-06-17
- Enahnce readme file.

## [0.2.0] - 2025-06-17
### Feature:
- Made userId optional (nullable)
- Added setUserId method to update user ID after initialization
- Updated Hive adapter to handle nullable userId
- Changed API to omit user_id field when null

## [0.1.1] - 2025-06-16
### Enhancement:
- Changed event ID generation to use UUIDv7 (time-ordered) instead of UUIDv4
- Better database performance with time-ordered UUIDv7
- Improved documentation with example values

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
