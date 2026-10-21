import {
  googleAndroidCallbackHtml,
  googleAndroidIntentLocation,
} from './google-android-callback';

describe('google Android browser return', () => {
  it('forwards only the sign-in fields into the app', () => {
    const location = googleAndroidIntentLocation({
      id_token: 'header.payload.sig',
      state: 'state-1',
      error: '',
      extra: 'drop-me',
    });

    expect(location.startsWith('intent://callback?')).toBe(true);
    expect(location).toContain('id_token=header.payload.sig');
    expect(location).toContain('state=state-1');
    expect(location).toContain('package=com.obic.app.obic_mobile');
    expect(location).toContain('scheme=signinwithgoogle');
    expect(location).not.toContain('extra');
    expect(location).not.toContain('drop-me');
  });

  it('serves a page that reads the fragment locally', () => {
    expect(googleAndroidCallbackHtml).toContain('window.location.hash');
    expect(googleAndroidCallbackHtml).toContain('scheme=signinwithgoogle');
    expect(googleAndroidCallbackHtml).not.toContain('header.payload.sig');
  });
});
