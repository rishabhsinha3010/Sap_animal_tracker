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

## Login and roles (XSUAA)

| Where | Login | Configured in |
|---|---|---|
| `cds watch` (default and `--profile hybrid`) | mocked test users above | `cds.requires.auth` in `package.json` |
| Cloud Foundry (`production`) and `--profile xsuaa` | real SAP users via XSUAA | `xs-security.json`, `mta.yaml` |

`xs-security.json` defines two roles. CAP strips the app prefix from the scopes, so they arrive as the
`Admin` and `User` roles the services already check (`@requires: 'Admin'`, `@restrict ... to: 'User'`):

| Role collection | Gives | Opens |
|---|---|---|
| `AnimalAdoption_Admin` | role `Admin` | admin app, `/admin` service |
| `AnimalAdoption_User` | role `User` | adopter app, `/user` service (own profile and applications) |

An adopter's profile is matched by **login email** (`Users.email = $user`). A new adopter opens
*Register* once, and the profile is created with their login email.

## Deploy to Cloud Foundry

The deployment reuses the existing HDI container `animal-adoption-tracker-db` (the one the `hybrid` profile uses)
and creates the XSUAA instance `animal-adoption-auth`.

In BAS, from the project folder:

```bash
cf login -a https://api.cf.us10-001.hana.ondemand.com   # org aa4e7ce5trial, space dev
npm run build:mta                                       # = mbt build -> mta_archives/animal-adoption-tracker_1.0.0.mtar
cf deploy mta_archives/animal-adoption-tracker_1.0.0.mtar
```

(Or right-click `mta.yaml` → *Build MTA Project*, then right-click the `.mtar` → *Deploy MTA Archive*.)

The deployment creates three apps:

- `animal-adoption-router`: **the URL to open**, e.g. `https://<org>-<space>-animal-adoption-router.cfapps.us10-001.hana.ondemand.com`
- `animal-adoption-srv`: the CAP service (only reached through the router)
- `animal-adoption-db-deployer`: deploys tables, views and sample data, then stops (that is normal)

Then assign the roles in the BTP cockpit: **Subaccount → Security → Role Collections → `AnimalAdoption_Admin` /
`AnimalAdoption_User` → Edit → Users**. Add the user's email (identity provider: Default identity provider) and save.
Log out and in again (*Sign out* on the landing page) so the new roles are in the token.

Note: every deployment re-imports the CSV sample data from `db/data`, so sample rows changed in the app are reset.

### Try XSUAA in BAS before or without deploying

After the first deployment (it creates `animal-adoption-auth`):

```bash
cds bind auth --to animal-adoption-auth            # once; stored in .cdsrc-private.json
cds watch --profile hybrid,xsuaa                   # terminal 1: CAP with HANA + XSUAA
npm run router:hybrid                              # terminal 2: app router on port 5000
```

Open the port 5000 URL that BAS offers (`https://port5000-...applicationstudio.cloud.sap/`). Port 4004 now answers 401,
because it expects an XSUAA token, which only the router adds.

## Project structure

```
xs-security.json              XSUAA: scopes, role templates, role collections (Admin, User)
mta.yaml                      Cloud Foundry deployment: srv + db deployer + app router, XSUAA, existing HDI
app/                          UI (Fiori elements apps)
  index.html                  landing page served at /
  router/                     app router (XSUAA login); xs-app.json = routes, build.js copies the UI into resources/
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
