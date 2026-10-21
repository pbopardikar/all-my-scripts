##### Set the following four values and run the script... #####
DD_BASE_ENDPOINT="MY_DATADOG_BASE_ENDPOINT" # Eg: https://api.datadoghq.com
API_KEY="MY_DATADOG_API_KEY"
APP_KEY="MY_DATADOG_APP_KEY"
CUSTOMER_NAME="MY_CUSTOMER_NAME"
###############################################################

FILE_NAME="${CUSTOMER_NAME}_Datadog_Report.txt"
TEMP_FILE_NAME="${CUSTOMER_NAME}_temp_dd_titles.txt"

DD_DASHBOARD_ENDPOINT="${DD_BASE_ENDPOINT}/api/v1/dashboard"
DD_MONITOR_ENDPOINT="${DD_BASE_ENDPOINT}/api/v1/monitor"
DD_SYNTHETICS_ENDPOINT="${DD_BASE_ENDPOINT}/api/v1/synthetics/tests"

rm ${TEMP_FILE_NAME}
rm ${FILE_NAME}
echo ${FILE_NAME}
touch ${FILE_NAME}

echo "-------------------------------------" >> ${FILE_NAME}
echo "ALL ENDPOINTS" >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}
echo ${DD_BASE_ENDPOINT} >> ${FILE_NAME}
echo ${DD_DASHBOARD_ENDPOINT} >> ${FILE_NAME}
echo ${DD_MONITOR_ENDPOINT} >> ${FILE_NAME}
echo ${DD_SYNTHETICS_ENDPOINT} >> ${FILE_NAME}


echo "" >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}
echo "SUMMARY" >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}

total_num_dashboards=$(curl -X GET ${DD_DASHBOARD_ENDPOINT} \
-H "Accept: application/json" \
-H "DD-API-KEY: ${API_KEY}" \
-H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '.dashboards | length')

echo "Total Number of Dashboards: $total_num_dashboards"  >> ${FILE_NAME}

total_num_monitors=$(curl -X GET ${DD_MONITOR_ENDPOINT} -H Accept:application/json -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq 'length')

echo "Total Number of Monitors: $total_num_monitors"  >> ${FILE_NAME}


total_num_synthetics=$(curl -X GET ${DD_SYNTHETICS_ENDPOINT} -H Accept:application/json -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '.tests | length')

echo "Total Number of Synthetic Tests: $total_num_synthetics"  >> ${FILE_NAME}

echo "" >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}
echo "SYNTHETIC MONITORING DETAILS" >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}

total_num_api_tests=$(curl -X GET ${DD_SYNTHETICS_ENDPOINT} -H Accept:application/json -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '[.tests[] | select(.type == "api")] | length')

echo "Number of Single-Request API Tests: $total_num_api_tests"  >> ${FILE_NAME}

total_num_browser_tests=$(curl -X GET ${DD_SYNTHETICS_ENDPOINT} -H Accept:application/json -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '[.tests[] | select(.type == "browser")] | length')

echo "Number of Browser Tests: $total_num_browser_tests"  >> ${FILE_NAME}

total_num_multistep_api_tests=$(curl -X GET ${DD_SYNTHETICS_ENDPOINT} -H Accept:application/json -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '[.tests[] | select(.type == "api-multi")] | length')

echo "Number of Multistep API Tests: $total_num_multistep_api_tests"  >> ${FILE_NAME}

total_num_mobile_app_tests=$(curl -X GET ${DD_SYNTHETICS_ENDPOINT} -H Accept:application/json -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '[.tests[] | select(.type == "mobile")] | length')

echo "Number of Mobile Application Tests: $total_num_mobile_app_tests"  >> ${FILE_NAME}

total_num_network_tests=$(curl -X GET ${DD_SYNTHETICS_ENDPOINT} -H Accept:application/json -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '[.tests[] | select(.type == "network")] | length')

echo "Number of Network Tests: $total_num_network_tests"  >> ${FILE_NAME}

echo "" >> ${FILE_NAME}

echo "-------------------------------------" >> ${FILE_NAME}
echo "ALL DASHBOARDS" >> ${FILE_NAME}
echo "ID | TITLE | NUMBER_OF_PANELS" >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}

# 1. Fetch all dashboard IDs and titles into a temporary file
curl -s -X GET "${DD_DASHBOARD_ENDPOINT}" \
  -H "Accept: application/json" \
  -H "DD-API-KEY: ${API_KEY}" \
  -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq -r '.dashboards[] | "\(.id)|\(.title)"' > "${TEMP_FILE_NAME}"

# 2. Loop through each dashboard, fetch its details, and write the row to your final file

total_panel_count=0
while IFS="|" read -r dash_id dash_title; do
  # Skip empty lines if any
  [ -z "$dash_id" ] && continue

  # Query the specific dashboard endpoint to extract actual panel/widget counts
  panel_count=$(curl -s -X GET "${DD_DASHBOARD_ENDPOINT}/${dash_id}" \
    -H "Accept: application/json" \
    -H "DD-API-KEY: ${API_KEY}" \
    -H "DD-APPLICATION-KEY: ${APP_KEY}" | jq '.widgets | length')

  # Print format: ID Title Count (with NO outer double quotes)
  echo "$dash_id | $dash_title | $panel_count" >> "${FILE_NAME}"

  ((total_panel_count += panel_count))

done < ${TEMP_FILE_NAME}

echo "" >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}
echo "Total number of panels: $total_panel_count"  >> ${FILE_NAME}
echo "-------------------------------------" >> ${FILE_NAME}

# Clean up temp file
rm ${TEMP_FILE_NAME}

echo ""
echo "Report generated in ${FILE_NAME}"
