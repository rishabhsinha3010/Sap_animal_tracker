# Animal Adoption Tracker

SAP CAP (Node.js) + Fiori elements (OData V4) app for animal shelters: adopters browse animals and apply,
shelter staff review applications and manage animals, shelters, health records and inspections.
The full requirements are in [`requirements.txt`](requirements.txt).

## Run it locally

```bash
npm install
npm run watch          # http://localhost:4004  (landing page with both apps)
```

| URL | App | Login (mocked auth, see `package.json`) |
|---|---|---|
| http://localhost:4004/ | Landing page | – |
| http://localhost:4004/adopter-app/index.html | Adopter app | `asha@example.com` / `user` (has a profile), `other@example.com` / `user` (new, no profile) |
| http://localhost:4004/admin-app/index.html | Admin app | `admin` / `admin` |

API tests (against a freshly started `cds watch`): `npm run test:api`

## Project structure

```
app/                          UI (Fiori elements apps)
  index.html                  landing page served at /
  services.cds                loads all UI annotations (common + both apps)
  common.cds                  field labels shared by both apps (annotated on the db entities)
  admin/                      ADMIN app  -> AdminService (/admin), served at /admin-app
    annotations/              one file per business object
      index.cds               entry point (imports the files below)
      applications.cds        Adoption Applications (Start Review / Approve / Reject)
      adoptions.cds           Adoptions (read-only, created on approval)
      animals.cds             Animals
      shelters.cds            Shelters
      health-records.cds      Health Records (Mark Recovered)
      inspections.cds         Inspections
    webapp/
      manifest.json           routes: Dashboard + list/object page per entity
      ext/dashboard/          custom start page: KPIs, charts, work queues
      css/style.css
      i18n/i18n.properties
  adopter/                    ADOPTER app -> UserService (/user), served at /adopter-app
    annotations/
      index.cds
      animals.cds             Browse Animals (Apply)
      applications.cds        My Applications (Withdraw)
      profile.cds             My Profile
    webapp/
      manifest.json           routes: Home + Animals + My Applications + Profile
      ext/home/               custom start page: welcome, my applications, available animals
      css/style.css
      i18n/i18n.properties
db/                           domain model (schema.cds, common.cds types) and CSV sample data
srv/                          AdminService and UserService (+ handlers)
test/api-test.sh              end-to-end API tests
scripts/                      sample data / image upload helpers
```

Where to change what:

- **A label of a field** (used by both apps): `app/common.cds`
- **Columns, filters, sections, buttons of a page**: `app/<app>/annotations/<object>.cds`
- **Routes / pages of an app**: `app/<app>/webapp/manifest.json`
- **Dashboard / Home page**: `app/<app>/webapp/ext/...` (XML view + controller, texts in `i18n`)
- **Status colours** (green/orange/red): the `...Criticality` fields calculated in `db/schema.cds`
