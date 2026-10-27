// Copies the UI into resources/ so the app router can serve it (see xs-app.json):
//   app/index.html           -> resources/index.html          (start page: opens the app for the role)
//   app/logged-out.html      -> resources/logged-out.html     (shown after Sign out, no login needed)
//   app/admin/webapp         -> resources/admin-app/          (same URLs as with cds watch)
//   app/adopter/webapp       -> resources/adopter-app/
//   app/shared               -> resources/shared/             (top bar used by both apps)
// Runs during the MTA build (mta.yaml) and before starting the router locally.
const fs = require('fs');
const path = require('path');

const APP = path.join(__dirname, '..');
const OUT = path.join(__dirname, 'resources');

fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });
fs.copyFileSync(path.join(APP, 'index.html'), path.join(OUT, 'index.html'));
fs.copyFileSync(path.join(APP, 'logged-out.html'), path.join(OUT, 'logged-out.html'));   // logoutPage (public)
fs.cpSync(path.join(APP, 'admin', 'webapp'), path.join(OUT, 'admin-app'), { recursive: true });
fs.cpSync(path.join(APP, 'adopter', 'webapp'), path.join(OUT, 'adopter-app'), { recursive: true });
fs.cpSync(path.join(APP, 'shared'), path.join(OUT, 'shared'), { recursive: true });   // top bar used by both apps
console.log('UI copied to', OUT);
