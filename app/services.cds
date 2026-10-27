// Entry point for the UI annotations (CAP loads app/services.cds automatically).
//   app/common.cds          labels shared by both apps
//   app/admin/annotations   admin app   (AdminService, /admin)
//   app/adopter/annotations adopter app (UserService, /user)
using from './common';
using from './admin/annotations';
using from './adopter/annotations';
