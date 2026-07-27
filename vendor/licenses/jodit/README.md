# Jodit vendor assets

- Package: jodit
- Version: 4.13.5
- Source: https://registry.npmjs.org/jodit/-/jodit-4.13.5.tgz
- License: MIT, see LICENSE.txt
- Runtime files copied from the npm package:
  - package/es2021/jodit.min.js -> vendor/javascript/jodit/jodit.min.js
  - package/es2021/jodit.min.css -> app/assets/stylesheets/jodit/jodit.min.css

Only the JavaScript runtime, CSS, package metadata, and license are vendored.
The full npm package is not committed.

The vendored JavaScript is based on the upstream es2021 UMD build. CDN loader
URLs for optional source editor integrations were removed because this project
must not contain CDN runtime references. The source editor plugin/button is also
disabled by application configuration.
