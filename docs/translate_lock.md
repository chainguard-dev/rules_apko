<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rules for translating apko.lock.json

<a id="translate_apko_lock"></a>

## translate_apko_lock

<pre>
load("@rules_apko//apko:translate_lock.bzl", "translate_apko_lock")

translate_apko_lock(<a href="#translate_apko_lock-name">name</a>, <a href="#translate_apko_lock-lock">lock</a>, <a href="#translate_apko_lock-target_name">target_name</a>)
</pre>

Repository rule to generate starlark code from an `apko.lock.json` file.

See [apko-cache.md](./apko-cache.md) documentation.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="translate_apko_lock-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="translate_apko_lock-lock"></a>lock |  label to the `apko.lock.json` file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="translate_apko_lock-target_name"></a>target_name |  internal. do not use!   | String | optional |  `""`  |


