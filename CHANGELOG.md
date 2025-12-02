# Changelog

## v1.2.2

### Added or Changed
- added Changelog
- introduced `callback_params/1` function without params key in parameter

### Deprecated
- deprecated usage of `callback_params/1` function with params key in Map parameter

## v1.2.1 - (2025-12-02)

### Added or Changed
- replaced CircleCI with Github workflow
- updated `credo` to v1.7 and use it in strict mode
- updated `secure_random` to v0.5.1
- fixed deprecation warnings about single quotes
- added more context to readme about custom state param

## v1.2.0 - (2023-07-29)

### Added or Changed
- introduced logout hint in logout URL
- added `credo` to CI

## v1.1.1 - (2023-07-23)

### Added or Changed
- made `state` parameter optional for `authorize_url!` function

## v1.1.0 - (2023-07-18)

### Added or Changed
- added required `state` parameter to `authorize_url!` function to identify custom requests/callbacks

### Contributors
- [@riccardomanfrin](https://github.com/riccardomanfrin)

## v1.0.0 - (2022-02-08)

### Added or Changed
- using v2.0 endpoints
- renewed Azure TLS certificate ([Azure TLS certificate changes](https://docs.microsoft.com/en-us/azure/security/fundamentals/tls-certificate-changes))
- added `code_challange` to params in authorization URL request
- introduced `Response`, `Http` and `Error` sub classes
- improved specs

### Removed 
- removed `json_web_token` dependency
- removed `nonce` validation

### Contributors
- [@whossname](https://github.com/whossname)