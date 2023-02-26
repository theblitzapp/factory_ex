## Changelog

# 0.3.3
- Make sure code is loaded before checking if functions exist

# 0.3.2
- Ensure app modules are compiled, avoiding Module.safe_concat errors re: schema modules
- Fix/add random field generators

# 0.3.1
- Make a fix for `factory_ex.gen` to prevent errors

# 0.3.0
- add Changeset validation to build for schemas

# 0.2.1
- add build_invalid_params
- add time generation fixes
- Blacklist Faker.Name
- Use context path in generation
- Underscore counter names properly

# 0.2.0
- Add mix factory generator command
- Add `keys` to `FactoryEx.build_params` with `:string` and `:camel_case` opts
- Add `FactoryEx.build_many_params`

# 0.1.0
- Initial Release
