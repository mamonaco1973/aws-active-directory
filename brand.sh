#!/bin/bash
# 🔧 This script updates branding for **ALL** supported AWS WorkSpaces client types.
# 💣 It FAILS FAST and logs helpful error messages.

# 🔍 Lookup the Directory ID based on the human-friendly directory name.
# ⚠️ Assumes the directory "mcloud.mikecloud.com" exists in the target AWS region.
directory_id=$(aws ds describe-directories \
  --region us-east-1 \
  --query "DirectoryDescriptions[?Name=='mcloud.mikecloud.com'].DirectoryId" \
  --output text)

# 📌 Set the branding parameters.
RESOURCE_ID=$directory_id                      # ✅ ID of the AWS WorkSpaces directory to brand
REGION="us-east-1"                             # 🌎 AWS region in use
LOGO_FILE="logo.png"                           # 🖼️ Image file to be shown as the logo
LOGIN_MESSAGE="@MikesCloudSolutions"           # 💬 Custom login message (change this to fit your brand)

# 🚨 SANITY CHECK: Make sure the logo file exists before continuing!
if [[ ! -f "$LOGO_FILE" ]]; then
  echo "ERROR: File $LOGO_FILE not found."
  exit 1                                        # ⛔ DIE FAST if logo is missing
fi

# 🧬 Convert the logo image to base64 in a single line (portable handling for different systems).
# GNU base64 uses -w 0, BSD/macOS uses -b 0. Try both.
BASE64_LOGO=$(base64 -w 0 "$LOGO_FILE" 2>/dev/null || base64 -b 0 "$LOGO_FILE")

# 📂 Create a temporary file to hold the JSON branding payload.
TMP_JSON=$(mktemp)

# 🛠️ Build the JSON payload with branding for ALL supported client types.
# Each client type gets the same logo and login message.
cat > "$TMP_JSON" <<EOF
{
  "ResourceId": "$RESOURCE_ID",
  "DeviceTypeWindows": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "$LOGIN_MESSAGE"
    }
  },
  "DeviceTypeWeb": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "$LOGIN_MESSAGE"
    }
  },
  "DeviceTypeIos": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "$LOGIN_MESSAGE"
    }
  },
  "DeviceTypeAndroid": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "$LOGIN_MESSAGE"
    }
  },
  "DeviceTypeLinux": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "$LOGIN_MESSAGE"
    }
  },
  "DeviceTypeMacOs": {
    "Logo": "$BASE64_LOGO",
    "LoginMessage": {
      "en_US": "$LOGIN_MESSAGE"
    }
  }
}
EOF

# 🚀 Execute the AWS CLI command to upload the branding.
# Uses the JSON we just built.
echo "NOTE: Uploading branding to all client types..."
aws workspaces import-client-branding \
  --cli-input-json file://"$TMP_JSON" \
  --region "$REGION"

# 🧹 Clean up the temp file no matter what happens.
STATUS=$?
rm -f "$TMP_JSON"

# ✅ SUCCESS or ❌ FAILURE feedback
if [[ $STATUS -eq 0 ]]; then
  echo "NOTE: Branding applied successfully to all clients."
else
  echo "ERROR: Failed to apply branding."
fi
