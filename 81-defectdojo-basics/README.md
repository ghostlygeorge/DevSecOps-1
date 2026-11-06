# Lab 81: Vulnerability Management with DefectDojo

## Goal
Learn DefectDojo's data model, create a product and engagement, upload
scanner reports (Brakeman, Bandit, ZAP) through the API with
`upload-results.py`, and triage findings (false positives).

DefectDojo centralises findings from many tools: it imports, merges, and
**de-duplicates** them, integrates with Jira, produces reports, and tracks
metrics.

Login: `$DOJO_URL` → `root` / `pdso-training`. The dashboard starts with 1
engagement and 0 findings.

## Data model

```
Product Type  (e.g. "Web Application", "Research and Development")   <- org / BU / portfolio
 └─ Product   (e.g. "Rails", "Django - Payment Service")             <- the thing you secure
     └─ Engagement  (e.g. "SAST Scan", "CI/CD", "Q3 pentest")         <- a testing activity with a timeline
         └─ Test    (one per imported report: "Bandit Scan", "ZAP Scan")
             └─ Finding  (Critical / High / Medium / Low / Info)
     Endpoints (hosts/URLs under test)
```
Choose product types so metrics reach the right teams.

## 1. Produce a report (Brakeman on rails)

```bash
git clone https://gitlab.practical-devsecops.training/pdso/rails.git webapp && cd webapp
docker run --rm -v $(pwd):/src hysnsec/brakeman -f json /src | tee brakeman-result.json
```

## 2. Create product + engagement (UI)
- **Add Product**: Name `Rails`, Description `Web Application based on the Rails framework`,
  Product Type `Web Application`, Business criticality `Medium`, Platform `Web`.
  (Product manager, technical contact, and team manager must be existing users.)
- **Engagements → Add New Interactive Engagement**: Name `SAST Scan`,
  Description `SAST activities`, target start/end dates, Status `In Progress`,
  Product `Rails` → **Done**.
- IDs show in the URL (`/product/3`, `/engagement/2`).

## 3. Upload via API

```bash
cp ../common/upload-results.py .         # or: curl https://gitlab.practical-devsecops.training/-/snippets/3/raw -o upload-results.py
pip3 install requests
python3 upload-results.py --help

export API_KEY=$(curl -s -XPOST -H 'content-type: application/json' $DOJO_URL/api/v2/api-token-auth/ \
  -d '{"username": "root", "password": "pdso-training"}' | jq -r '.token')
echo $API_KEY        # empty? Dojo is still booting, or the 2h machine timer expired.
# (or copy it from $DOJO_URL/api/key-v2, or run `dojo_token` from lab-env.sh)

python3 upload-results.py --host $DOJO_HOST --api_key $API_KEY \
  --engagement_id 2 --product_id 3 --lead_id 1 --environment "Production" \
  --result_file brakeman-result.json --scanner "Brakeman Scan"
# Successfully uploaded the results to DefectDojo
```

| Arg | Value |
|---|---|
| `--host` | `dojo-<id>.lab.practical-devsecops.training` |
| `--api_key` | API v2 token |
| `--engagement_id` / `--product_id` | from the URLs. **Yours will differ.** |
| `--lead_id` | user ID of the tester (root = 1) |
| `--environment` | must match an existing **Environment** name exactly (e.g. "Production") |
| `--scanner` | DefectDojo **parser name**, case-sensitive: `Bandit Scan`, `ZAP Scan`, `Brakeman Scan` ... |
| `--result_file` | report path |

Not every tool has a parser. Check the
[supported parsers](https://docs.defectdojo.com/en/connecting_your_tools/parsers/)
and use the format each one expects (ZAP = XML, Bandit = JSON, Nmap = XML).

**HTTP 500?** Usually: an environment name that doesn't exist (check
**Engagements → Environments**), a wrong scanner string, or a wrong file
format for that parser.

## 4. Triage
`$DOJO_URL/engagement/2` → **Brakeman Scan** test → select findings → **Bulk Edit**
→ Severity Medium, tick **False Positive** → Submit. Status becomes
*Inactive, False Positive*. Dojo remembers that on reimport (dedupe), so
the same FP doesn't come back next scan.

## 5. Same for Bandit (django.nv)

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp2 && cd webapp2
pip3 install bandit==1.7.1
bandit -r . -f json | tee bandit-output.json         # 1 high, 1 medium, 1 low
python3 ../upload-results.py --host $DOJO_HOST --api_key $API_KEY --engagement_id 1 --product_id 1 \
  --lead_id 1 --environment "Production" --result_file bandit-output.json --scanner "Bandit Scan"
```

## Challenge: ZAP results → Dojo manually

```bash
docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 \
  zap-baseline.py -t $PROD_URL -d -x zap-output.xml          # -x XML: the ZAP parser expects XML
python3 upload-results.py --host $DOJO_HOST --api_key $API_KEY --engagement_id 1 --product_id 1 \
  --lead_id 1 --environment "Production" --result_file zap-output.xml --scanner "ZAP Scan"
```

Explore the product, engagement, and test pages and watch the URL change.
That's where you find the IDs. The `500` you may hit with ZAP comes from
the wrong arguments (JSON instead of XML, or the scanner name). See the
[importing docs](https://defectdojo.github.io/django-DefectDojo/integrations/importing/).

## Notes
- `upload-results.py` in `common/` is a **reconstruction** with the same CLI.
  The original is a course snippet whose source wasn't shown.
- In production, use `reimport-scan` with a fixed test to update findings
  (closing fixed ones) instead of creating a new test every run.
