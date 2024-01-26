# Share-post Extension For Quarto

The Share-post extension will embed a copy of a social media post in a Quarto document.

## Installing

```bash
quarto add dragonstyle/share-post
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

Simply place the shortcode where you'd like placeholder content to be generated. Be default, the lipsum shortcode will emit 5 paragraphs of lipsum. For example:

```
{{< share-post https://sciencemastodon.com/@gdyson/111371030805595929 >}}
```

## Supported Services

Share-post currently supports the following services, and should generate a formatted, embedded post from them.

- Mastodon
- LinkedIn
- Threads
- Instagram
- Pinterest
- Twitter

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).
