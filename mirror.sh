#!/usr/bin/env bash
set -euo pipefail

# Variables
PROJECT_DIR="$PWD"
MIRROR_DIR="$PWD/S3-mirror" # The S3-mirror is just my naming. You can name as you please.
CLI_CONFIG_FILE="/home/zeno/.terraformrc" # Define the your file path mine is .terraformrc (If you ever had a terraform cli config before, you can put that)
NETWORK_MIRROR_URL="https://do2sts5f46nf8.cloudfront.net" # Use your exact CloudFront URL for the network mirror configuration
PLATFORMS=("linux_amd64" "darwin_amd64" "darwin_arm64" "windows_amd64")

# Comment this part if you are going to use this in a clean directory with where the directory is freshly created.
# Comment or Uncomment it doesn't really matter the script will still work but recommand to do so in case of there might be file conflicts.
echo "Cleaning up previous state, lock file, CLI config, and setting up mirror directory..."
rm -rf .terraform
rm -rf .terraform.lock.hcl
# rm -rf "$MIRROR_DIR" /// Uncomment this if you want to reuse the script to popultae the mirror directory with provider zip files.
rm -f "$CLI_CONFIG_FILE"

# Creating the mirror directory 
mkdir -p "$MIRROR_DIR" 

# Downloading the required providers form the official registry
echo "Initializing Terraform modules (discovering providers from public registry)..."
cd "$PROJECT_DIR" 
terraform init -input=false # initializes a Terraform working directory without prompting for interactive input


# Mirroring the downloaded provider form the official registry to the mirror directory with multiple platforms
PLATFORM_FLAGS=()
for p in "${PLATFORMS[@]}"; do
  PLATFORM_FLAGS+=("-platform=$p")
done

echo "Mirroring provider packages for platforms: ${PLATFORMS[*]} into $MIRROR_DIR..."
terraform providers mirror "${PLATFORM_FLAGS[@]}" "$MIRROR_DIR"

echo "Generating multi-platform lock file (.terraform.lock.hcl)..."
terraform providers lock "${PLATFORM_FLAGS[@]}"

# Writing the terraform cli config file for the network mirror configuration
echo "Generating local .terraformrc with network_mirror configuration..."

cat << EOF > "$CLI_CONFIG_FILE"
provider_installation {
  network_mirror {
    url = "$NETWORK_MIRROR_URL"
  }
}
EOF


# Uploading the contents inside the mirror directory into the S3 bucket
S3_BUCKET="s3://provider-cache-tf" 

if [ -n "$S3_BUCKET" ]; then
  echo "Uploading mirror to S3 bucket: $S3_BUCKET..."
  aws s3 cp "$MIRROR_DIR" "$S3_BUCKET" --recursive
  echo "Mirror uploaded successfully."
fi

# Running a final init to confirm if the network_mirror configuration actually works.
# For this time terrafrom will look for the .terraformrc and connect to the network mirror registry
# If this work you will get the same messege like you download from the official registry
echo "Running final initialization to confirm network mirror configuration is active..."
terraform init -input=false

echo "✅ Full Terraform network mirror workflow completed."
echo "Mirror folder: $MIRROR_DIR"
echo "Lock file updated with zh hashes for all platforms."
echo "Local CLI configuration file generated at: $CLI_CONFIG_FILE"
