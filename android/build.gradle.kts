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

fun org.gradle.api.Project.ensureAndroidNamespace() {
    val androidExt = extensions.findByName("android") ?: return
    val getNamespace = androidExt::class.java.methods.firstOrNull {
        it.name == "getNamespace" && it.parameterTypes.isEmpty()
    } ?: return
    val setNamespace = androidExt::class.java.methods.firstOrNull {
        it.name == "setNamespace" && it.parameterTypes.size == 1
    } ?: return

    val currentNamespace = getNamespace.invoke(androidExt) as? String
    if (!currentNamespace.isNullOrBlank()) return

    val manifestFile = file("src/main/AndroidManifest.xml")
    val manifestNamespace = if (manifestFile.exists()) {
        val text = manifestFile.readText()
        Regex("""package\s*=\s*"([^"]+)"""")
            .find(text)
            ?.groupValues
            ?.getOrNull(1)
    } else {
        null
    }

    // Workaround for third-party plugins that do not define namespace.
    val fallbackNamespace =
        manifestNamespace ?: "dev.flutter.${name.replace('-', '_')}"
    setNamespace.invoke(androidExt, fallbackNamespace)
}

subprojects {
    pluginManager.withPlugin("com.android.application") {
        ensureAndroidNamespace()
    }
    pluginManager.withPlugin("com.android.library") {
        ensureAndroidNamespace()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
