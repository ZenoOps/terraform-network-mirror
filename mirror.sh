#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$PWD"
MIRROR_DIR="$PWD/S3-mirror"
CLI_CONFIG_FILE="/home/zeno/.terraformrc" # Define the your local file path mine is .terraformrc
NETWORK_MIRROR_URL="https://do2sts5f46nf8.cloudfront.net" # Use your exact CloudFront URL for the network mirror configuration
PLATFORMS=("linux_amd64" "darwin_amd64" "darwin_arm64" "windows_amd64")

# --- 1. CLEANUP AND INITIAL SETUP ---
# This step on
echo "Cleaning up previous state, lock file, CLI config, and setting up mirror directory..."
rm -rf .terraform
rm -rf .terraform.lock.hcl
rm -rf "$MIRROR_DIR"
rm -f "$CLI_CONFIG_FILE" # Ensure local CLI config is clean before first init
mkdir -p "$MIRROR_DIR" 

echo "Initializing Terraform modules (discovering providers from public registry)..."
cd "$PROJECT_DIR"
terraform init -input=false


PLATFORM_FLAGS=()
for p in "${PLATFORMS[@]}"; do
  PLATFORM_FLAGS+=("-platform=$p")
done

echo "Mirroring provider packages for platforms: ${PLATFORMS[*]} into $MIRROR_DIR..."
terraform providers mirror "${PLATFORM_FLAGS[@]}" "$MIRROR_DIR"

echo "Generating multi-platform lock file (.terraform.lock.hcl)..."
terraform providers lock "${PLATFORM_FLAGS[@]}"

# --- 4. GENERATE FINAL .terraformrc CONFIGURATION ---
echo "Generating local .terraformrc with network_mirror configuration..."
# This is the crucial change: using your network_mirror block
cat << EOF > "$CLI_CONFIG_FILE"
provider_installation {
  network_mirror {
    url = "$NETWORK_MIRROR_URL"
  }
}
EOF

# --- 5. UPLOAD TO S3 ---
S3_BUCKET="s3://provider-cache-tf" # This should align with your CloudFront distribution origin

if [ -n "$S3_BUCKET" ]; then
  echo "Uploading mirror to S3 bucket: $S3_BUCKET..."
  aws s3 cp "$MIRROR_DIR" "$S3_BUCKET" --recursive
  echo "Mirror uploaded successfully."
fi

# Optional: Run a final init to confirm the network_mirror configuration works
# NOTE: Terraform will use the local .terraformrc and attempt to connect
# to the CloudFront URL, which should now serve the newly uploaded providers.
echo "Running final initialization to confirm network mirror configuration is active..."
terraform init -input=false

echo "✅ Full Terraform network mirror workflow completed."
echo "Mirror folder: $MIRROR_DIR"
echo "Lock file updated with zh hashes for all platforms."
echo "Local CLI configuration file generated at: $CLI_CONFIG_FILE"
