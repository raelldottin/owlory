# Career Domain

## Owns

- Career wins.
- Impact records.
- Interview stories.
- Metrics/evidence attached to career records.

## Does Not Own

- Writing pipeline stages.
- Daily focus ranking.
- Pattern calibration beyond contributing records.

## Depends On

- `CareerStore`.
- `ItemListRepository<CareerRecord>`.

## Exposes

- `CareerRecord`, `CareerRecordType`, `CareerStore`.

## Change Safely

- Preserve raw evidence and metrics fields.
- Keep edit and creation paths deterministic.
- Add lower-layer tests when changing store behavior.

## Verify

- `make test-domain DOMAIN=career`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/CareerStoreTests`
