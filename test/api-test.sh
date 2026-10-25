#!/usr/bin/env bash
# End-to-end API test for the admin and user flows (Step 1).
# Runs against a FRESH server, because it changes data:
#   cds watch            (in-memory SQLite, restart = fresh data)
#   bash test/api-test.sh                 -> tests http://localhost:4004
#   BASE=http://localhost:4005 bash test/api-test.sh
# Needs curl and jq. Every check prints PASS or FAIL; the exit code is the number of failures.

BASE=${BASE:-http://localhost:4004}
FAILS=0; PASSES=0

# ---------- tiny helpers ----------
# req USER:PASS METHOD PATH [JSON-BODY]  -> sets $CODE (HTTP status) and $BODY (response text)
req() {
  local auth=$1 method=$2 path=$3 body=$4 out
  # no -u at all for "not logged in" (curl -u "" would wait for a password on the keyboard)
  local login=(); [ -n "$auth" ] && login=(-u "$auth")
  if [ -n "$body" ]; then
    out=$(curl -s -w '\n%{http_code}' "${login[@]}" -X "$method" -H 'Content-Type: application/json' --data "$body" "$BASE$path")
  else
    out=$(curl -s -w '\n%{http_code}' "${login[@]}" -X "$method" "$BASE$path")
  fi
  CODE=${out##*$'\n'}; BODY=${out%$'\n'*}
}
# check "description" ACTUAL EXPECTED
check() {
  if [ "$2" == "$3" ]; then PASSES=$((PASSES+1)); echo "PASS  $1"
  else FAILS=$((FAILS+1)); echo "FAIL  $1  (expected '$3', got '$2')"; [ -n "$BODY" ] && echo "      body: ${BODY:0:300}"; fi
}
j() { echo "$BODY" | jq -r "$1"; }   # read a value from the last response

ADMIN=admin:admin; ASHA=asha@example.com:user; OTHER=other@example.com:user; MEERA=meera@example.com:user; NOPROFILE=user:user
BRUNO=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa; MISTY=bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb; ROCKY=cccccccc-cccc-cccc-cccc-cccccccccccc
COCO=dddddddd-dddd-dddd-dddd-dddddddddddd; LEO=eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee; BELLA=a7a7a7a7-a7a7-a7a7-a7a7-a7a7a7a7a7a7
KIWI=a8a8a8a8-a8a8-a8a8-a8a8-a8a8a8a8a8a8
S1=11111111-1111-1111-1111-111111111111; S2=22222222-2222-2222-2222-222222222222; S3=33333333-3333-3333-3333-333333333333
APP1=d1d1d1d1-d1d1-d1d1-d1d1-d1d1d1d1d1d1; APP2=d2d2d2d2-d2d2-d2d2-d2d2-d2d2d2d2d2d2; APP3=d3d3d3d3-d3d3-d3d3-d3d3-d3d3d3d3d3d3
APP6=d6d6d6d6-d6d6-d6d6-d6d6-d6d6d6d6d6d6; INSP=f2f2f2f2-f2f2-f2f2-f2f2-f2f2f2f2f2f2; ADP1=f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1

echo "== security =="
req "" GET /admin/Animals;                     check "no login -> 401"                 "$CODE" 401
req "$ASHA" GET /admin/Animals;                check "user on admin service -> 403"    "$CODE" 403

echo "== seeded data and dashboard views =="
req "$ADMIN" GET '/admin/Animals?$count=true&$top=0'; check "8 animals"                "$(j '."@odata.count"')" 8
req "$ADMIN" GET /admin/AnimalSummary
check "summary total"       "$(j '.value[0].totalAnimals')" 8
check "summary available"   "$(j '.value[0].availableAnimals')" 6
check "summary adopted"     "$(j '.value[0].adoptedAnimals')" 1
check "summary unavailable" "$(j '.value[0].unavailableAnimals')" 1
req "$ADMIN" GET /admin/ApplicationsByStatus;  check "5 statuses in bar chart" "$(j '.value|length')" 5
req "$ADMIN" GET /admin/AdoptionTrend;         check "trend Sep 2026 = 1" "$(j '[.value[]|select(.year==2026 and .month==9)][0].total')" 1
req "$ADMIN" GET "/admin/ShelterOccupancy($S1)"; check "Happy Paws occupancy 3" "$(j .currentOccupancy)" 3
req "$ADMIN" GET "/admin/ShelterOccupancy($S3)"; check "Green Tails occupancy 1 (Leo adopted)" "$(j .currentOccupancy)" 1
req "$ADMIN" GET "/admin/OverdueCheckups?\$filter=animal_ID%20eq%20$ROCKY"; check "Rocky has overdue checkups" "$(j '.value|length>0')" true
req "$ADMIN" GET "/admin/Users?\$filter=email%20eq%20'asha@example.com'"; check "calculated fullName" "$(j '.value[0].fullName')" "Asha Reddy"
req "$ADMIN" GET "/admin/AdoptionApplications($APP3)?\$expand=adoption(\$expand=inspections)"
check "application -> adoption link" "$(j .adoption.adoptionID)" ADP-0001
check "adoption -> inspection"       "$(j '.adoption.inspections|length')" 1
req "$ADMIN" GET "/admin/AdoptionApplications($APP1)"
check "canStartReview on Submitted" "$(j .canStartReview)" true
check "canDecide on Submitted"      "$(j .canDecide)" false

echo "== user: profile =="
req "$ASHA" GET /user/Users;                   check "asha sees only her profile" "$(j '.value|length')" 1
req "$NOPROFILE" POST /user/Users '{"firstName":"Test","lastName":"User","phoneNumber":"abc"}'
check "bad phone number -> 400" "$CODE" 400
req "$OTHER" POST /user/Users '{"firstName":"Olga","lastName":"Other","phoneNumber":"+91 90000 11111","city":"Chennai"}'
check "other@ registers -> 201"  "$CODE" 201
check "email taken from login"   "$(j .email)" other@example.com
req "$OTHER" POST /user/Users '{"firstName":"Olga","lastName":"Again"}'
check "second registration -> 409" "$CODE" 409
OTHER_ID=$(curl -s -u "$OTHER" "$BASE/user/Users" | jq -r '.value[0].ID')
req "$OTHER" PATCH "/user/Users($OTHER_ID)" '{"city":"Madurai"}'; check "edit own profile" "$(j .city)" Madurai

echo "== user: browse and apply =="
req "$ASHA" GET "/user/Animals?\$expand=shelter,healthRecords&\$count=true"
check "user sees 8 animals"           "$(j '."@odata.count"')" 8
check "Leo (Adopted) cannot be applied for" "$(j '.value[]|select(.name=="Leo")|.canApply')" false
check "health records expanded"       "$(j '.value[]|select(.name=="Rocky")|.healthRecords|length')" 2
check "internal diagnosis hidden"     "$(j '.value[]|select(.name=="Rocky")|.healthRecords[0]|has("diagnosis")')" false
req "$ASHA" POST "/user/Animals($COCO)/UserService.apply" '{"reasonForAdoption":"Bunny for my daughter","housingType":"Apartment","hasOtherPets":false,"petExperience":"Had rabbits"}'
check "apply for Coco -> 200"  "$CODE" 200
check "new application Submitted" "$(j .status)" Submitted
check "next code APP-0007"     "$(j .applicationID)" APP-0007
NEW_APP=$(j .ID)
req "$ASHA" POST "/user/Animals($COCO)/UserService.apply" '{"reasonForAdoption":"again"}'
check "duplicate application -> 409" "$CODE" 409
req "$ASHA" POST "/user/Animals($LEO)/UserService.apply" '{"reasonForAdoption":"please"}'
check "apply for adopted animal -> 409" "$CODE" 409
req "$ASHA" POST "/user/Animals($KIWI)/UserService.apply" '{"reasonForAdoption":"Moved, no cat now","housingType":"Independent House"}'
check "re-apply after a rejection is allowed" "$CODE" 200
req "$ASHA" POST "/user/Animals($BELLA)/UserService.apply" '{}'
check "apply without reason -> 400" "$CODE" 400
req "$NOPROFILE" POST "/user/Animals($BELLA)/UserService.apply" '{"reasonForAdoption":"x"}'
check "apply without profile -> 403" "$CODE" 403
req "$ADMIN" POST "/user/Animals($BELLA)/UserService.apply" '{"reasonForAdoption":"x"}'
check "admin cannot apply -> 403" "$CODE" 403
req "$OTHER" POST "/user/Animals($BELLA)/UserService.apply" '{"reasonForAdoption":"Newly registered and ready"}'
check "newly registered user can apply" "$CODE" 200

echo "== user: my applications =="
req "$ASHA" GET "/user/AdoptionApplications?\$expand=history,adoption(\$expand=inspections),documents&\$orderby=applicationID"
check "asha sees only her 5 applications" "$(j '.value|length')" 5
check "history of the new application" "$(j ".value[]|select(.ID==\"$NEW_APP\")|.history|length")" 1
check "approved one shows the inspection result" "$(j '.value[]|select(.applicationID=="APP-0003")|.adoption.inspections[0].result')" Pending
check "rejected one has red criticality" "$(j '.value[]|select(.applicationID=="APP-0004")|.statusCriticality')" 1
req "$ASHA" GET "/user/AdoptionApplications($APP2)"; check "cannot read someone else's application" "$CODE" 404
req "$ASHA" POST /user/AdoptionApplications "{\"animal_ID\":\"$MISTY\",\"reasonForAdoption\":\"direct create\",\"history\":[{\"newStatus\":\"Approved\"}]}"
check "direct create still works" "$CODE" 201
DIRECT=$(j .ID)
req "$ASHA" GET "/user/ApplicationHistory?\$filter=application_ID%20eq%20$DIRECT"
check "smuggled history row ignored (only the Submitted row)" "$(j '[.value[].newStatus]|join(",")')" Submitted
req "$ASHA" PATCH "/user/AdoptionApplications($DIRECT)" "{\"animal_ID\":\"$LEO\",\"housingDetails\":\"2BHK\"}"
check "edit own Submitted application" "$CODE" 200
check "animal cannot be changed"       "$(j .animal_ID)" "$MISTY"
req "$ASHA" POST "/user/AdoptionApplications($NEW_APP)/UserService.withdraw" '{}'; check "withdraw -> 204" "$CODE" 204
req "$ASHA" POST "/user/AdoptionApplications($NEW_APP)/UserService.withdraw" '{}'; check "withdraw twice -> 409" "$CODE" 409
req "$ASHA" POST "/user/Animals($COCO)/UserService.apply" '{"reasonForAdoption":"Changed my mind back"}'
check "re-apply after withdraw is allowed" "$CODE" 200
req "$ASHA" GET "/user/AdoptionApplications($APP3)"; check "approved application has canWithdraw false" "$(j .canWithdraw)" false

echo "== admin: review flow =="
req "$ADMIN" POST "/admin/AdoptionApplications($APP6)/AdminService.approve" '{}'
check "approve a Submitted one -> 409" "$CODE" 409
req "$ADMIN" POST "/admin/AdoptionApplications($APP6)/AdminService.startReview" '{}'; check "startReview" "$CODE" 204
req "$ADMIN" POST "/admin/AdoptionApplications($APP6)/AdminService.startReview" '{}'; check "startReview twice -> 409" "$CODE" 409
req "$ADMIN" POST "/admin/AdoptionApplications($APP6)/AdminService.rejectApplication" '{}'
check "reject without reason -> 400" "$CODE" 400
req "$ADMIN" POST "/admin/AdoptionApplications($APP6)/AdminService.rejectApplication" '{"reason":"Landlord does not allow pets"}'
check "reject with reason" "$CODE" 204
req "$ADMIN" GET "/admin/AdoptionApplications($APP6)"; check "status Rejected" "$(j .status)" Rejected

req "$ADMIN" POST "/admin/AdoptionApplications($APP1)/AdminService.startReview" '{}'
req "$ADMIN" POST "/admin/AdoptionApplications($APP1)/AdminService.approve" '{"remarks":"Lovely home"}'
check "approve Bruno's application" "$CODE" 204
req "$ADMIN" GET "/admin/AdoptionApplications($APP1)?\$expand=adoption,history"
check "adoption created with next code" "$(j .adoption.adoptionID)" ADP-0002
check "history has 3 rows"              "$(j '.history|length')" 3
req "$ADMIN" GET "/admin/Animals($BRUNO)";      check "Bruno is Adopted" "$(j .adoptionStatus)" Adopted
req "$ADMIN" GET "/admin/Shelters($S1)";        check "Happy Paws occupancy down to 2" "$(j .currentOccupancy)" 2
req "$ADMIN" DELETE "/admin/AdoptionApplications($APP1)"; check "delete application -> 405" "$CODE" 405
req "$ADMIN" PATCH "/admin/AdoptionApplications($APP2)" '{"status":"Approved"}'
req "$ADMIN" GET "/admin/AdoptionApplications($APP2)"; check "status cannot be PATCHed" "$(j .status)" "Under Review"

echo "== admin: animals and shelters =="
req "$ADMIN" POST /admin/Animals "{\"name\":\"Tiger\",\"species\":\"Cat\",\"shelter_ID\":\"$S3\",\"adoptionFee\":600}"
check "create animal -> 201" "$CODE" 201
check "animal code ANM-0009" "$(j .animalID)" ANM-0009
TIGER=$(j .ID)
req "$ADMIN" GET "/admin/Shelters($S3)"; check "Green Tails occupancy 2" "$(j .currentOccupancy)" 2
req "$ADMIN" PATCH "/admin/Animals($TIGER)" "{\"shelter_ID\":\"$S2\"}"; check "move animal" "$CODE" 200
req "$ADMIN" GET "/admin/ShelterOccupancy?\$orderby=shelterName"
check "occupancy after move (City Care, Green Tails, Happy Paws)" "$(j '[.value[].currentOccupancy]|join(",")')" "4,1,2"
req "$ADMIN" DELETE "/admin/Animals($TIGER)"; check "delete animal" "$CODE" 204
req "$ADMIN" GET "/admin/Shelters($S2)"; check "City Care occupancy back to 3" "$(j .currentOccupancy)" 3

echo "== admin: health records =="
req "$ADMIN" POST /admin/HealthRecords "{\"animal_ID\":\"$ROCKY\",\"checkupDate\":\"2026-10-24\",\"healthStatus\":\"Under Treatment\",\"vaccinationStatus\":\"Vaccinated\",\"veterinarianName\":\"Dr. Rao\"}"
check "create health record" "$CODE" 201
HR=$(j .ID)
req "$ADMIN" GET "/admin/Animals($ROCKY)"; check "animal follows newest record" "$(j .vaccinationStatus)" Vaccinated
req "$ADMIN" POST "/admin/HealthRecords($HR)/AdminService.markRecovered" '{}'; check "markRecovered" "$CODE" 204
req "$ADMIN" GET "/admin/Animals($ROCKY)"
check "Rocky Healthy"   "$(j .healthStatus)" Healthy
check "Rocky Available" "$(j .adoptionStatus)" Available

echo "== admin: inspections and documents =="
req "$ADMIN" PATCH "/admin/Inspections($INSP)" '{"result":"Validated"}'; check "validate inspection" "$CODE" 200
req "$ADMIN" GET "/admin/Adoptions($ADP1)"
check "adoption Completed" "$(j .status)" Completed
check "completedBy admin"  "$(j .completedBy)" admin
req "$ADMIN" POST /admin/ApplicationDocuments "{\"application_ID\":\"$APP3\",\"fileName\":\"virus.exe\",\"mediaType\":\"application/x-msdownload\"}"
check "wrong file type -> 400" "$CODE" 400
req "$ADMIN" POST /admin/ApplicationDocuments "{\"application_ID\":\"$APP3\",\"fileName\":\"approval.pdf\",\"mediaType\":\"application/pdf\",\"documentType\":\"Approval Letter\",\"url\":\"https://res.cloudinary.com/demo/image/upload/sample.pdf\"}"
check "document metadata -> 201" "$CODE" 201
DOC=$(j .ID)
CODE=$(printf '%%PDF-1.4 test' | curl -s -o /dev/null -w '%{http_code}' -u "$ADMIN" -X PUT -H 'Content-Type: application/pdf' --data-binary @- "$BASE/admin/ApplicationDocuments($DOC)/content")
check "upload file content" "$CODE" 204
req "$ASHA" GET /user/ApplicationDocuments; check "asha sees her document" "$(j '.value[0].fileName')" approval.pdf
req "$MEERA" GET /user/ApplicationDocuments; check "meera sees none" "$(j '.value|length')" 0
CODE=$(curl -s -o /dev/null -w '%{http_code}' -u "$ASHA" "$BASE/user/ApplicationDocuments($DOC)/content")
check "asha downloads her document" "$CODE" 200

echo "== retention =="
req "$OTHER" DELETE "/user/Users($OTHER_ID)"; check "user delete -> 204" "$CODE" 204
req "$ADMIN" GET "/admin/Users($OTHER_ID)";    check "profile only deactivated" "$(j .status)" Inactive

echo
echo "$PASSES passed, $FAILS failed"
exit $FAILS
