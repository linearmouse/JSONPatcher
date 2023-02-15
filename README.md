# [WIP] JSONPatcher

Patch JSON / [JSONC](https://github.com/microsoft/node-jsonc-parser).

## Background

When JSON / JSONC is parsed and re-encoded, some "trivial" information
will be lost, such as whitespaces and comments.

Normally, this is not a problem for JSON, but for JSONC (or JSON5), it
is a bad experience for users to find that comments are removed.

There are two approaches for preserving these "trivial" things when JSONC
is modified programmatically:

1. Build a parser that deserializes the "trivial" things into structures,
   and then serializes them back into JSONC.
2. Generate the final JSONC content from the original JSONC content and
   the modified JSON content.

The first approach requires the developers to modify their structures by
adding fields to store these "trivial" data. Therefore, this module
implements the second approach.

## Goals

The goal of this module is not to "efficiently" parse JSONC, but to make
it easier for developers to switch from JSON to JSONC.

## Current status

- [x] Scanner
- [x] Parser
- [ ] Patcher
- [ ] Formatter
