# NeMo Common Library Chart

This is a library helm chart of templates that are useful for consistency across helm charts and because defined templates exist in the global scope.

All charts should use it's templates if they have relevant objects defined. When importing the chart dependency, use the version ">=0.1.0-0" to ensure all versions are captured and it stays up to date.
