# Hugo Theme Console (Customized)

This repository contains a heavily customized version of the [Hugo Theme Console](https://github.com/mrmierzejewski/hugo-theme-console).

## Customizations

This theme has been modified specifically for the personal website of Willi Mutschler. Key customizations include:

-   **Homepage (`layouts/index.html`):** Completely rewritten to feature a flexbox layout with a biography and profile picture.
-   **Base Layout (`layouts/_default/baseof.html`):** Removed the default terminal prompt header.
-   **List Layout (`layouts/_default/list.html`):** Customized headers and date formatting for posts.
-   **Footer (`layouts/partials/footer.html`):** Simplified to include a single link to the Privacy Policy.
-   **Styles (`static/hugo-theme-console/css/console.css`):**
    -   Added extensive custom CSS for publications (`.publication-title`, `.publication-links`).
    -   Added custom styling for collapsible abstract details blocks (`details.abstract`).
    -   Updated code block styling and hid backticks.
    -   Hid the blinking terminal cursor effect.

## Upstream Synchronization (March 2026)

This custom theme was synchronized with upstream fixes to ensure compatibility with Hugo v0.146.0+:

1.  **Hugo Deprecations Resolved:** Replaced the deprecated `.Data.Pages` syntax with modern `.Pages` syntax in `list.html`, `gallery/list.html`, and `sitemap.xml`.
2.  **Markdown Render Hooks:** Added upstream markdown render hooks (`layouts/_default/_markup/`) to support native Hugo rendering for links (opening external links in new tabs), images (making them responsive), and headings.

## Updating the Theme

Because this theme is heavily customized directly within the `themes/hugo-theme-console` directory, you cannot simply `git pull` from the upstream repository without overwriting the personalizations listed above.

If future updates from upstream are required, they should be reviewed and applied manually as patches. You can use the provided `.orig` files as a reference point for what the original theme looked like before customizations were applied.

## GitHub Actions

The site is deployed via GitHub Actions (`.github/workflows/hugo.yml`), currently utilizing Hugo version `0.146.0`.
