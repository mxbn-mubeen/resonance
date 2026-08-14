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

subprojects {
    project.plugins.withId("com.android.library") {
        val library = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        library.buildToolsVersion = "34.0.0"
        if (library.namespace == null) {
             when (project.name) {
                 "isar_flutter_libs" -> library.namespace = "dev.isar.isar_flutter_libs"
                 "on_audio_query_android" -> library.namespace = "com.lucasjosino.on_audio_query"
                 "audio_service" -> library.namespace = "com.ryanheise.audio_service"
                 "audio_session" -> library.namespace = "com.ryanheise.audio_session"
                 "just_audio" -> library.namespace = "com.ryanheise.just_audio"
                 "just_waveform" -> library.namespace = "com.ryanheise.just_waveform"
                 "permission_handler_android" -> library.namespace = "com.baseflow.permissionhandler"
                 "sqflite_android" -> library.namespace = "com.tekartik.sqflite"
                 "workmanager" -> library.namespace = "dev.fluttercommunity.workmanager"
                 "jni" -> library.namespace = "com.github.dart_lang.jni"
                 "jni_flutter" -> library.namespace = "com.github.dart_lang.jni_flutter"
                 else -> library.namespace = "com.mxbn.${project.name.replace("-", "_")}"
             }
        }
    }

    val targetJvm = when (project.name) {
        "on_audio_query_android" -> "1.8"
        else -> "17"
    }

    project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(targetJvm))
        }
    }
    project.tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = targetJvm
        targetCompatibility = targetJvm
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
