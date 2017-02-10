# RailsPackager

## Usage

Include this gem in your Rails project's `Gemfile`:
```
gem "rails_packager"
```

Package your project as a gzipped tar file via:
```
$ rake package
```

or via:
```
$ rails_package
```

## Options

You can enable verbose mode, and customize the name of the tarball via the following:
```
$ rake package[customized-tarball-name] verbose=true
$ rails_package -v --name customized-tarball-name
```

## Configuration

You can include or exclude specific files, or customize what actions happen
before, after, or during packaging. Below is the default config that will be
used, unless you defined a `.rails-package` YAML file customizing the config.
```yaml
---
env: {}
name: 
include: 
exclude:
- "**/.git"
- tmp
before:
- - bundle install --deployment --without development test
  - unsetenv:
    - RUBYOPT
    - RUBYLIB
    - BUNDLER_ORIG_GEM_PATH
    - BUNDLER_ORIG_PATH
    env:
      GEM_PATH: "${BUNDLER_ORIG_GEM_PATH}"
- gem install bundler --install-dir vendor/bundle
- - bundle exec rake assets:precompile
  - unsetenv:
    - RUBYOPT
    - RUBYLIB
    - BUNDLER_ORIG_GEM_PATH
    - BUNDLER_ORIG_PATH
    env:
      RAILS_ENV: production
      GEM_PATH: "${BUNDLER_ORIG_GEM_PATH}"
package: tar --no-recursion --files-from @{files_file} -zcvf @{name}.tar.gz
after: 
```

In most parts of the configuration, you may use a few special variables, such as
`${ENV_VARIABLE}` to embed a value from an environment variable. You may use
`@{name}` to embed the name of the project (which defaults to the parent folder
name, but can be overridden in the config or via a command line option). The
`@{files}` variable will expand to all files that will be included in the
package, and `@{files_file}` will generate a temporary file used during
packaging that contains every file listed one per line (the path to this
temporary file will be the expanded result).

## JBundler

If you have a `Jarfile` in your project, and you have not customized the
`before` configuration, then `jbundler` will automatically be inserted after the
bundle and installing of bundler with this command:
```
jbundle install --vendor
```

## License

This project rocks and uses MIT-LICENSE.
