load("@bazel_skylib//rules:build_test.bzl", "build_test")
load(":tree.bzl", "staged_tree_check", "tree")

tree(name = "input_tree")

staged_tree_check(
    name = "staged_tree",
    src = ":input_tree",
)

build_test(
    name = "test",
    targets = [":staged_tree"],
)
