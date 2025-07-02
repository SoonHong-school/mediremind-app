buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.4.1") // or your current Android Gradle Plugin version
        classpath("com.google.gms:google-services:4.3.15") // Firebase plugin classpath
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
