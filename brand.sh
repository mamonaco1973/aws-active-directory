#!/bin/bash

directory_id=$(aws ds describe-directories \
  --region us-east-1 \
  --query "DirectoryDescriptions[?Name=='mcloud.mikecloud.com'].DirectoryId" \
  --output text)

# Set these values
RESOURCE_ID=$directory_id
REGION="us-east-1"
LOGO_FILE="logo.png"

# Check if logo exists
if [[ ! -f "$LOGO_FILE" ]]; then
  echo "❌ File $LOGO_FILE not found."
  exit 1
fi

# Encode logo into a single-line base64 string
BASE64_LOGO=$(base64 -w 0 "$LOGO_FILE" 2>/dev/null || base64 -b 0 "$LOGO_FILE")

# Generate temp JSON
TMP_JSON=$(mktemp)
cat > "$TMP_JSON" <<EOF
{
  "ResourceId": "$RESOURCE_ID",
  "DeviceTypeWindows": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "@MikesCloudSolutions"
    }
  },
  "DeviceTypeWeb": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "@MikesCloudSolutions"
    }
  }
}
EOF

# Push branding
echo "🚀 Uploading branding..."
aws workspaces import-client-branding \
  --cli-input-json file://"$TMP_JSON" \
  --region "$REGION"

STATUS=$?
rm -f "$TMP_JSON"

if [[ $STATUS -eq 0 ]]; then
  echo "✅ Branding applied successfully."
else
  echo "❌ Failed to apply branding."
fi
