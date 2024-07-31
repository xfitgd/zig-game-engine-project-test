
IF "%1" == "android" (
aapt2 compile --dir res -o zig-out/res.zip
aapt2 link -o zig-out/output.apk -I %2/platforms/android-%3/android.jar zig-out/res.zip --java . --manifest AndroidManifest.xml
zip -r zig-out/output.apk lib/
zip -r zig-out/output.apk assets/
zipalign -p -f -v 4 zig-out/output.apk zig-out/unsigned.apk
apksigner sign --ks debug.keystore --ks-pass pass:android --out zig-out/signed.apk zig-out/unsigned.apk
)

shader_compile