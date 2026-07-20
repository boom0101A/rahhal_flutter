allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Flutter plugins pin inconsistent compileSdk versions: some old ones (e.g.
// geocoding_android 3.x) hard-code 33 while their AndroidX deps now demand
// 34+, and newer ones (e.g. sqflite_android 2.4.3) reference SDK-36-only
// symbols like Build.VERSION_CODES.BAKLAVA / Locale.of / Thread.threadId().
// Force every Android subproject (plugin) to compile against SDK 36 — the
// same level the app uses — so all of them build consistently without having
// to upgrade each plugin individually.
subprojects {
    // :app is force-evaluated early by the evaluationDependsOn(":app") above,
    // so guard against registering afterEvaluate on an already-evaluated
    // project (only :app, which already uses compileSdk 36 and needs no bump).
    if (!project.state.executed) {
        afterEvaluate {
            val androidExtension = extensions.findByName("android")
            if (androidExtension != null) {
                try {
                    androidExtension.javaClass
                        .getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                        .invoke(androidExtension, 36)
                } catch (_: Exception) {
                    // Not an Android extension exposing compileSdkVersion(int) — ignore.
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
