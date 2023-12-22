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
| <a id="translate_apko_lock-lock"></a>lock |  label to the <code>apko.resolved.json</code> file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="translate_apko_lock-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="translate_apko_lock-target_name"></a>target_name |  internal. do not use!   | String | optional | <code>""</code> |


