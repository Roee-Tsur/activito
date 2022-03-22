package surk.inc.activito

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
   /* @Override
    protected fun onCreate(@Nullable savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val info: PackageInfo = getPackageManager().getPackageInfo(
                    "surk.inc.activito",  //Insert your own package name.
                    PackageManager.GET_SIGNATURES)
            for (signature in info.signatures) {
                val md: MessageDigest = MessageDigest.getInstance("SHA")
                md.update(signature.toByteArray())
                Log.d("KeyHash:", Base64.encodeToString(md.digest(), Base64.DEFAULT))
            }
        } catch (e: PackageManager.NameNotFoundException) {
        } catch (e: NoSuchAlgorithmException) {
        }
    }*/
}
