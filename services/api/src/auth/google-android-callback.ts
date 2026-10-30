// Made by Dr Ali
// Android Google sign-in returns through the browser. This route only sends
// the browser back into the app. It does not verify the token or open a session.

const CALLBACK_KEYS = ['id_token', 'state', 'error', 'error_description'] as const;

const APP_PACKAGE = 'com.obic.app.obic_mobile';
const APP_SCHEME = 'signinwithgoogle';

/** Chrome Custom Tab target. The ID token stays in the app intent, not a session. */
export function googleAndroidIntentLocation(
  source: Record<string, unknown> | null | undefined,
): string {
  const params = new URLSearchParams();
  if (source) {
    for (const key of CALLBACK_KEYS) {
      const value = source[key];
      if (typeof value !== 'string' || value.length === 0) continue;
      params.append(key, value.slice(0, 20_000));
    }
  }
  return (
    `intent://callback?${params.toString()}` +
    `#Intent;package=${APP_PACKAGE};scheme=${APP_SCHEME};end`
  );
}

/**
 * Implicit-flow responses put the ID token in the URL fragment, which the
 * server never receives. This page reads that fragment in the browser and
 * jumps back into the app.
 */
export const googleAndroidCallbackHtml = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="referrer" content="no-referrer">
<title>OBIC</title>
</head>
<body>
<script>
(function () {
  var incoming = new URLSearchParams(window.location.hash.replace(/^#/, ''));
  var search = new URLSearchParams(window.location.search);
  var out = new URLSearchParams();
  ['id_token', 'state', 'error', 'error_description'].forEach(function (key) {
    var value = incoming.get(key) || search.get(key) || '';
    if (!value) return;
    out.set(key, value.slice(0, 20000));
  });
  window.location.replace(
    'intent://callback?' + out.toString() +
    '#Intent;package=${APP_PACKAGE};scheme=${APP_SCHEME};end'
  );
})();
</script>
</body>
</html>
`;
