# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

$channel = "$Env:CHANNEL"
If ([string]::IsNullOrEmpty($channel)) { $channel = "unstable" }

$product = "$Env:PRODUCT"
If ([string]::IsNullOrEmpty($product)) { $product = "chef-workstation" }

$version = "$Env:VERSION"
If ([string]::IsNullOrEmpty($version)) { $version = "latest" }

Write-Output "--- Downloading $channel $product $version"
$download_url = C:\opscode\omnibus-toolchain\embedded\bin\mixlib-install.bat download --url --channel "$channel" "$product" --version "$version"
$package_file = "$Env:Temp\$(Split-Path -Path $download_url -Leaf)"
Invoke-WebRequest -OutFile "$package_file" -Uri "$download_url"

Write-Output "--- Checking that $package_file has been signed."
If ((Get-AuthenticodeSignature "$package_file").Status -eq 'Valid') {
  Write-Output "Verified $package_file has been signed."
}
Else {
  Write-Output "Exiting with an error because $package_file has not been signed. Check your omnibus project config."
  exit 1
}

Write-Output "--- Installing $channel $product $version"
Start-Process "$package_file" /quiet -Wait

Write-Output "--- Running verification for $channel $product $version"

# reload Env:PATH to ensure it gets any changes that the install made (e.g. C:\opscode\chef-workstation\bin\ )
$Env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# chef-run version ensures our bin ends up on path and the basic ruby env is working.
chef-run --version
If ($lastexitcode -ne 0) { Exit $lastexitcode }

# Ensure our ChefDK works
chef env
If ($lastexitcode -ne 0) { Exit $lastexitcode }
