<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rules for translating apko.lock.json

<a id="translate_apko_lock"></a>

## translate_apko_lock

<pre>
translate_apko_lock(<a href="#translate_apko_lock-name">name</a>, <a href="#translate_apko_lock-lock">lock</a>, <a href="#translate_apko_lock-repo_mapping">repo_mapping</a>, <a href="#translate_apko_lock-target_name">target_name</a>)
</pre>

Repository rule to generate starlark code from an `apko.lock.json` file.

See [apko-cache.md](./apko-cache.md) documentation.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="translate_apko_lock-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="translate_apko_lock-lock"></a>lock |  label to the `apko.lock.json` file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="translate_apko_lock-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |
| <a id="translate_apko_lock-target_name"></a>target_name |  internal. do not use!   | String | optional |  `""`  |


