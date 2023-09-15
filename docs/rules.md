<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="apko_image"></a>

## apko_image

<pre>
apko_image(<a href="#apko_image-name">name</a>, <a href="#apko_image-architecture">architecture</a>, <a href="#apko_image-args">args</a>, <a href="#apko_image-config">config</a>, <a href="#apko_image-contents">contents</a>, <a href="#apko_image-output">output</a>, <a href="#apko_image-tag">tag</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apko_image-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apko_image-architecture"></a>architecture |  -   | String | optional | <code>""</code> |
| <a id="apko_image-args"></a>args |  -   | List of strings | optional | <code>[]</code> |
| <a id="apko_image-config"></a>config |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apko_image-contents"></a>contents |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apko_image-output"></a>output |  -   | String | optional | <code>"oci"</code> |
| <a id="apko_image-tag"></a>tag |  -   | String | required |  |


<a id="apko_bazelrc"></a>

## apko_bazelrc

<pre>
apko_bazelrc(<a href="#apko_bazelrc-name">name</a>, <a href="#apko_bazelrc-kwargs">kwargs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="apko_bazelrc-name"></a>name |  <p align="center"> - </p>   |  <code>"apko_bazelrc"</code> |
| <a id="apko_bazelrc-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


